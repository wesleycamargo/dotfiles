#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DevContainer
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ThemeUrl = 'https://gist.githubusercontent.com/wesleycamargo/06b58b472fe0cded2e6d6451ea0778bd/raw/1c952297121a50826ef6f849bb7ee8c11d8e09a6/oh-my-posh-az-cli-az-pwsh.json'

function Install-OhMyPosh {
    $existing = Get-Command oh-my-posh -ErrorAction SilentlyContinue

    if ($existing -and -not $Force) {
        Write-Host "Oh My Posh already installed: $($existing.Source)"
        return
    }

    Write-Host 'Installing Oh My Posh...'

    if ($IsWindows) {
        winget install JanDeDobbeleer.OhMyPosh --source winget
    }
    else {
        curl -s https://ohmyposh.dev/install.sh | bash -s
    }
}

function Get-OhMyPoshPath {
    $command = Get-Command oh-my-posh -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    $candidates = @(
        '/usr/local/bin/oh-my-posh',
        "$HOME/.local/bin/oh-my-posh",
        "$HOME/bin/oh-my-posh"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw 'Oh My Posh was not found after installation.'
}

function Install-TerminalIcons {
    $existing = Get-Module -ListAvailable -Name Terminal-Icons

    if ($existing -and -not $Force) {
        Write-Host 'Terminal-Icons already installed.'
        return
    }

    Write-Host 'Installing Terminal-Icons...'

    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default
    }

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    Install-Module Terminal-Icons -Scope CurrentUser -Force
}

function Get-ProfileConfiguration {
    $ohMyPoshPath = Get-OhMyPoshPath

    if ($DevContainer) {
        $configDir = Join-Path $HOME '.config/oh-my-posh'
        $themePath = Join-Path $configDir 'theme.omp.json'

        New-Item -ItemType Directory -Path $configDir -Force | Out-Null

        if ((Test-Path $themePath) -and -not $Force) {
            Write-Host "Oh My Posh theme already exists: $themePath"
        }
        else {
            Write-Host "Downloading Oh My Posh theme to: $themePath"
            Invoke-WebRequest -Uri $ThemeUrl -OutFile $themePath
        }

        return @{
            ProfilePath = $PROFILE.CurrentUserAllHosts
            ConfigPath  = $themePath
            OhMyPosh    = $ohMyPoshPath
        }
    }

    return @{
        ProfilePath = $PROFILE.CurrentUserAllHosts
        ConfigPath  = $ThemeUrl
        OhMyPosh    = $ohMyPoshPath
    }
}

function Set-PowerShellProfile {
    $config = Get-ProfileConfiguration

    $profilePath = $config.ProfilePath
    $profileDir = Split-Path $profilePath

    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

    if ($IsWindows -and -not $DevContainer) {
        $initLine = "oh-my-posh init pwsh --config '$($config.ConfigPath)' | Invoke-Expression"
    }
    else {
        $initLine = "& '$($config.OhMyPosh)' init pwsh --config '$($config.ConfigPath)' | Invoke-Expression"
    }

    $profileContent = @"
# Terminal Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# Oh My Posh
$initLine
"@

    Set-Content -Path $profilePath -Value $profileContent

    Write-Host "PowerShell profile configured: $profilePath"
}

function Set-GitAliases {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'Git not found. Skipping git aliases.'
        return
    }

    $existingAlias = git config --global alias.lg 2>$null

    if ($existingAlias -and -not $Force) {
        Write-Host 'Git alias "lg" already configured.'
        return
    }

    Write-Host 'Configuring git aliases...'

    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

Install-OhMyPosh
Install-TerminalIcons
Set-PowerShellProfile
Set-GitAliases

if ($DevContainer) {
    Write-Host 'Devcontainer terminal setup complete.'
}
else {
    Write-Host 'Terminal setup complete.'
}