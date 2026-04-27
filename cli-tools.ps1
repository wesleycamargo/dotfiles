#Dev Tools
winget install --id Git.Git -e --source winget
winget install --id GitExtensionsTeam.GitExtensions -e --source winget

# Azure
winget install --id Microsoft.AzureCLI -e --source winget

az extension add --name azure-devops
az extension add --name bicep


# PowerShell Modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name Az.DevOps -Force -AllowClobber
