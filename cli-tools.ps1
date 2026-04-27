# Determine if sudo is needed (Linux non-root only)
$isRoot = $IsLinux -and ((& id -u) -eq "0")
$useSudo = $IsLinux -and -not $isRoot

function Invoke-Sudo {
    param([string]$Cmd, [string[]]$Args)
    if ($useSudo) { & sudo $Cmd @Args } else { & $Cmd @Args }
}

# Dev Tools
if ($IsWindows) {
    winget install --id Git.Git -e --source winget
    winget install --id GitExtensionsTeam.GitExtensions -e --source winget
}
elseif ($IsLinux) {
    if (Get-Command apt-get -ErrorAction SilentlyContinue) {
        Invoke-Sudo apt-get @("update")
        Invoke-Sudo apt-get @("install", "-y", "git")
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        Invoke-Sudo dnf @("install", "-y", "git")
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
        $installScript = & curl -fsSL https://aka.ms/InstallAzureCLIDeb
        if ($useSudo) { $installScript | sudo bash } else { $installScript | bash }
    }
    elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        Invoke-Sudo rpm @("--import", "https://packages.microsoft.com/keys/microsoft.asc")
        Invoke-Sudo dnf @("install", "-y", "azure-cli")
    }
    elseif (Get-Command brew -ErrorAction SilentlyContinue) {
        brew install azure-cli
    }
}

# # Azure CLI extensions (only if az is available after install)
# if (Get-Command az -ErrorAction SilentlyContinue) {
#     az extension add --name azure-devops
#     az extension add --name bicep
# }


# PowerShell Modules
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default
}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name Az -Force -AllowClobber
