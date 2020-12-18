#!/bin/bash

echo "Criando variaveis no ambiente"
#Nome do ResourceGroup
ResourceGroup=RG-TESTE-SCRIPT 
#Usuário ADM na VM
adminuser=admin_cloud 
#Senha do usuário ADM na VM (Gerado com lastpass) OBS: As aspas simples não fazem parte da senha
adminpass='@#Sin@#2434$' 
#Nome para o StorageAccount de Diagnostico
StorageACname=stgtestescript
#ID da subscription
subscription=8ef5e401-3f0b-4c63-bc19-d6554f622469
#Size da VM
Size=Standard_D2s_v3
#Sistema Operacional da VM
SO=win2019datacenter
#Localização dos recursos
location="Brazil South"
#Tag
tagOwner="Master"
#Nome da VM
VMname=VM-TESTE-SCRIPT
#VNet em que será implantada a VM
vnetAddress=10.20.0.0/16
subnetAddress=10.20.0.0/24
vnetName=VNET-TESTE-SCRIPT
subnetName=SNET-TESTE-SCRIPT
nsgSubnetName=NSG-TESTE-SCRIPT
#Tamanho e tipo de discos da VM
SOdisk=128
Datadisk=128
SOdisksku=Standard_LRS
Datadisksku=Standard_LRS


echo "Criando ResourceGroup"
az group create -l "$location" -n $ResourceGroup --subscription $subscription \
--tags Owner="$tagOwner"
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando Vnet"
az network vnet create \
  --resource-group $ResourceGroup \
  --location "$location" \
  --address-prefix $vnetAddress \
  --name $vnetName
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando NSG para Subnet"
az network nsg create \
  --resource-group $ResourceGroup \
  --name $nsgSubnetName
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando Subnet"
az network vnet subnet create \
  --resource-group $ResourceGroup \
  --vnet-name $vnetName \
  --name $subnetName \
  --address-prefixes $subnetAddress \
  --network-security-group $nsgSubnetName
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Confirmando SubnetID"
subnetId=$(az network vnet subnet show \
--resource-group $ResourceGroup --name $subnetName \
--vnet-name $vnetName --query id -o tsv)
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando Storage Account"
az storage account create -n $StorageACname -g $ResourceGroup --sku Standard_LRS
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando IP Público como Estático"
az network public-ip create --resource-group $ResourceGroup --name PIP-$VMname --allocation-method Static
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando NIC"
az network nic create \
  --resource-group $ResourceGroup \
  --name NIC-$VMname \
  --subnet $subnetId \
  --public-ip-address PIP-$VMname
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando VM"
  az vm create \
    --resource-group $ResourceGroup \
    --name $VMname \
    --location "$location" \
    --size $Size \
    --os-disk-size-gb $SOdisk \
    --storage-sku os=$SOdisksku 0=$Datadisksku \
    --data-disk-sizes-gb $Datadisk \
    --nics NIC-$VMname \
    --image $SO \
    --boot-diagnostics-storage $StorageACname \
    --admin-username $adminuser \
    --admin-password $adminpass
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Fixando IP Privado"
IPVM=$(az vm show -g $ResourceGroup -n $VMname --show-details --query 'privateIps' --out tsv)
IPCONFIG=$(az network nic show \
-g $ResourceGroup \
-n NIC-$VMname \
--query 'ipConfigurations[0].name' -o tsv)
az network nic ip-config update -g $ResourceGroup --nic-name NIC-$VMname \
-n $IPCONFIG \
--private-ip-address $IPVM
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Verificando SourceIP"
sourceIp=$(curl ifconfig.me)
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando regra para acesso externo a porta 3389(RDP)"
az network nsg rule create \
  --resource-group $ResourceGroup \
  --nsg-name $nsgSubnetName \
  --name Allow-RDP \
  --priority 300 \
  --source-address-prefixes $sourceIp/32 --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 3389 --access Allow \
  --protocol Tcp --description "Allow RDP from my home"
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando Vault de Backup"
az backup vault create --resource-group $ResourceGroup \
    --name RSV-$ResourceGroup \
    --location "$location"
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Baixando template de Policy Backup"
wget -q https://raw.githubusercontent.com/EdesanTomaz/AzureCLI-CreateVM/master/policy-backup-azure.json -O policy-backup-azure.json
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Alterando template"
sed -i "s/RG/$ResourceGroup/g" policy-backup-azure.json
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Registrando Policy Backup"
az backup policy set --policy policy-backup-azure.json \
--resource-group $ResourceGroup --vault-name RSV-$ResourceGroup
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Habilitando Backup"
az backup protection enable-for-vm \
    --resource-group $ResourceGroup \
    --vault-name RSV-$ResourceGroup \
    --vm $VMname \
    --policy-name Diario-BR
if [ "$?" -ne "0" ];
then
exit 1
break
fi
echo "Validando instalacao"
Resultdeploy=$(az vm show -g $ResourceGroup -n $VMname --show-details --query 'powerState' -o tsv)
PubIPshow=$(az vm show -d -g $ResourceGroup -n $VMname --query 'publicIps' -o tsv)
echo $Resultdeploy
if [ "$Resultdeploy" == "VM running" ]; then
    echo "Deploy da VM $VMname concluida. Para acessar utilize o IP $PubIPshow"
else
    echo  "Erro no deploy da VM $VMname "
fi
