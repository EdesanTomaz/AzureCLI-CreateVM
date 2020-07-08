#!/bin/bash

echo "Criando variaveis no ambiente"
#Nome do ResourceGroup
ResourceGroup=git-rg-project 
#Usuário ADM na VM
adminuser=gitadmin 
#Senha do usuário ADM na VM (Gerado com lastpass) OBS: As aspas simples não fazem parte da senha
adminpass='APMCZV2!bObZ' 
#Nome para o StorageAccount de Diagnostico
StorageACname=girprojectvmdiag
#ID da subscription
subscription=000aaaaa-000aaa-000aa-000aaaaaaa
#Size da VM
Size=Standard_D2s_v3
#Sistema Operacional da VM
SO=win2016datacenter
#Localização dos recursos
location="Brazil South"
#Tag
tagOwner="Master"
#Nome da VM
VMname=LabGitVM
#VNet em que será implantada a VM
vnetAddress=10.0.0.0/16
subnetAddress=10.0.0.0/24
vnetName=Vnet-Lab-Git
subnetName=Subnet-Lab-Git
nsgSubnetName=NSG-Subnet-Lab-Git
#Tamanho e tipo de discos da VM
SOdisk=128
Datadisk=30
SOdisksku=Premium_LRS
Datadisksku=StandardSSD_LRS


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

echo "Criando IP Público como Statico"
az network public-ip create --resource-group $ResourceGroup --name PubIP-$VMname --allocation-method Static
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando NIC"
az network nic create \
  --resource-group $ResourceGroup \
  --name Nic-$VMname \
  --subnet $subnetId \
  --public-ip-address PubIP-$VMname
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
    --nics Nic-$VMname \
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
-n Nic-$VMname \
--query 'ipConfigurations[0].name' -o tsv)
az network nic ip-config update -g $ResourceGroup --nic-name Nic-$VMname \
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
  --name Allow-Source-Home \
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
    --name $ResourceGroup-Vault \
    --location "$location"
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Baixando template de Policy Backup"
wget -q https://raw.githubusercontent.com/alancorreia/AzureCLI-CreateVM/master/policy-backup-azure.json -O policy-backup-azure.json
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
--resource-group $ResourceGroup --vault-name $ResourceGroup-Vault
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Habilitando Backup"
az backup protection enable-for-vm \
    --resource-group $ResourceGroup \
    --vault-name $ResourceGroup-Vault \
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
