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
#Localização
location="Brazil South"
#Tag
tagOwner="Master"
#Nome da VM
VMname=GitVM
#VNet em que será implantada a VM
RGVnet=NOMEDORESOURCEGRUPDAVNET
SubnetName=NOMEDASUBNET
VnetName=NOMEDAVNET
#Tamanho e tipo de discos da VM
SOdisk=128
Datadisk=30
SOdisksku=Premium_LRS
Datadisksku=StandardSSD_LRS

echo "Confirmando SubnetID"
subnetId=$(az network vnet subnet show \
--resource-group $RGVnet --name $SubnetName \
--vnet-name $VnetName --query id -o tsv)
if [ "$?" -ne "0" ];
then
exit 1
break
fi

echo "Criando ResourceGroup"
az group create -l "$location" -n $ResourceGroup --subscription $subscription \
--tags Owner="$tagOwner"
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
echo $Resultdeploy
if [ "$Resultdeploy" == "VM running" ]; then
    echo "Deploy daS VM $VMname concluida"
else
    echo  "Erro no deploy da VM $VMname "
fi