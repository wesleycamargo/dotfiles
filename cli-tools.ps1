# Dev Tools
if ($IsWindows) {
    winget install --id Git.Git -e --source winget
    winget install --id GitExtensionsTeam.GitExtensions -e --source winget
}
elseif ($IsLinux) {
    if (Get-Command apt-get -ErrorAction SilentlyContinue) {
        sudo apt-get update
        sudo apt-get install -y git
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        sudo dnf install -y git
    }
    elseif (Get-Command brew -ErrorAction SilentlyContinue) {
        brew install git
    }
    # GitExtensions is Windows-only, skipping
}

# Azure CLI
if ($IsWindows) {
    winget install --id Microsoft.AzureCLI -e --source winget
}
elseif ($IsLinux) {
    if (Get-Command apt-get -ErrorAction SilentlyContinue) {
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo dnf install -y azure-cli
    }
    elseif (Get-Command brew -ErrorAction SilentlyContinue) {
        brew install azure-cli
    }
}

az extension add --name azure-devops
az extension add --name bicep


# PowerShell Modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name Az.DevOps -Force -AllowClobber
