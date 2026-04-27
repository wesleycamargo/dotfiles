#Dev Tools
winget install --id Git.Git -e --source winget
winget install --id GitExtensionsTeam.GitExtensions -e --source winget
winget install --id Microsoft.VisualStudioCode -e --source winget

# Azure
winget install --id Microsoft.AzureCLI -e --source winget

# Install azure extension
az extension add --name azure-devops
az extension add --name bicep

#Work tools
winget install --id Learnpulse.Screenpresso -e --source winget
winget install --id Microsoft.Sysinternals.ZoomIt -e --source winget
