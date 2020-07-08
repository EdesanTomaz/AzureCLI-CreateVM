# AzureCLI-CreateVM

Este é um simples script em bash que pode ajudar a simplificar a criação de ambiente com uma VM em Azure através da CLI.
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



Algumas ferramentas abaixo podem ser utilizadas para melhores estudos e resultados em implantações através de scripts

VisualStudio Code - https://code.visualstudio.com/ <br>
AzureCLI - https://docs.microsoft.com/pt-br/cli/azure/install-azure-cli?view=azure-cli-latest <br>
WSL - https://docs.microsoft.com/pt-br/windows/wsl/install-win10 <br>
CloudShell Azure - https://docs.microsoft.com/pt-br/azure/cloud-shell/overview
