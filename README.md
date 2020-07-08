# AzureCLI - Criando um ambiente via ShellScript

Este é um simples script em bash que pode ajudar a simplificar a criação de ambiente com uma VM em Azure através da CLI.<br><br><br>
- Criadores <br>
Alan Correia<br>
[André Terasaka](https://github.com/terasaka)<br><br>

Você pode executar este script tanto de um S.O Windows,Linux,MacOS ou CloudShell no portal Azure.

O conteudo necessário está no script CriarVM.sh. Devemos apenas alterar as variaveis comentadas nele antes da execução.
Ao final deste deploy via CLI, você deverá ter os seguintes recursos implantados:

#### - ResourceGroup
#### - Vnet e Subnet com NSG
#### - StorageAccount
#### - Placa de Rede com IP Publico e Privado
#### - VM Windows
#### - Disco de SO Premium
#### - Disco de Dados Standard
#### - IP privado fixo
#### - Vault de Backup configurado

# Executando o script <br>
Na sua maquina, após iniciar o shell e realizar o [az login](https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli?view=azure-cli-latest) Poderemos seguir com os demais passos

Após iniciado o Shell, iremos realizar o download do script<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/raw/master/img/azurecli.png)<br><br>

Necessário dar permissão de execução ao script<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell2.png?raw=true)<br><br>

Encontre sua SubscriptionID no painel de subscrições da Azure<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell4.png?raw=true) <br><br>
Vamos editar o script. Você pode apenas editar a Subscription ou todas as variáveis para o ambiente<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell3.png?raw=true)
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell5.png?raw=true)<br><br>
Após alterado o script e salvo, executaremos da seguinte forma<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell6.png?raw=true)<br><br>

Ao final da execução, você deve receber o retorno da seguinte maneira em caso de sucesso<br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureshell7.png?raw=true)<br><br>

Através do acesso remoto via RDP, deveremos conseguir acessar a VM <br>
![alt text](https://github.com/alancorreia/AzureCLI-CreateVM/blob/master/img/azureclirdp.png?raw=true)<br><br>

### Algumas ferramentas abaixo podem ser utilizadas para melhores estudos e resultados em implantações através de scripts

VisualStudio Code - https://code.visualstudio.com/ <br>
AzureCLI - https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli?view=azure-cli-latest <br>
WSL - https://docs.microsoft.com/pt-br/windows/wsl/install-win10 <br>
