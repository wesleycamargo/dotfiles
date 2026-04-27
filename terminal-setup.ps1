#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Install-NerdFont {
    param([switch]$Force)

    if ($IsWindows) {
        $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        $tempZip = "$env:TEMP\Meslo.zip"
        $tempDir = "$env:TEMP\Meslo"
    }
    else {
        $fontsDir = "$HOME/.local/share/fonts/nerd-fonts"
        $tempZip = '/tmp/Meslo.zip'
        $tempDir = '/tmp/Meslo'
    }

    $alreadyInstalled = Test-Path (Join-Path $fontsDir 'MesloLGMNerdFont-Regular.ttf')
    if ($alreadyInstalled -and -not $Force) {
        Write-Host 'MesloLGM Nerd Font already installed, skipping. Use -Force to reinstall.'
        return
    }

    Write-Host 'Installing MesloLGM Nerd Font...'
    New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null
    Invoke-WebRequest -Uri 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip' -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
    Get-ChildItem -Path $tempDir -Filter '*.ttf' | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $fontsDir -Force
    }
    Remove-Item -Path $tempZip, $tempDir -Recurse -Force

    if ($IsLinux) {
        & fc-cache -fv
    }
}

function Install-OhMyPosh {
    param([switch]$Force)

    $alreadyInstalled = $null -ne (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue)
    if ($alreadyInstalled -and -not $Force) {
        Write-Host 'Oh My Posh already installed, skipping. Use -Force to reinstall.'
        return
    }

    Write-Host 'Installing Oh My Posh...'
    if ($IsWindows) {
        winget install JanDeDobbeleer.OhMyPosh --source winget
    }
    else {
        curl -s https://ohmyposh.dev/install.sh | bash
    }
}

function Initialize-OhMyPosh {
    $theme = 'https://gist.githubusercontent.com/wesleycamargo/06b58b472fe0cded2e6d6451ea0778bd/raw/1c952297121a50826ef6f849bb7ee8c11d8e09a6/oh-my-posh-az-cli-az-pwsh.json'

    $ompCmd = Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue
    if (-not $ompCmd -and $IsLinux) {
        # Common install locations when PATH hasn't been refreshed yet
        $candidates = @('/usr/local/bin/oh-my-posh', "$HOME/.local/bin/oh-my-posh")
        $ompBin = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($ompBin) {
            $env:PATH = "$(Split-Path $ompBin):$env:PATH"
        }
        else {
            Write-Warning 'oh-my-posh binary not found, skipping prompt init.'
            return
        }
    }

    $profileDir = Split-Path $PROFILE.AllUsersAllHosts
    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    Set-Content $PROFILE.AllUsersAllHosts "oh-my-posh init pwsh --config '$theme' | Invoke-Expression"
}

function Set-GitAliases {
    param([switch]$Force)

    $existing = git config --global alias.lg 2>$null
    if ($existing -and -not $Force) {
        Write-Host 'Git alias "lg" already configured, skipping. Use -Force to reconfigure.'
        return
    }

    Write-Host 'Configuring git aliases...'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

################################
# Main
################################
Install-NerdFont -Force:$Force
Install-Module Terminal-Icons -Force
Import-Module Terminal-Icons
Install-OhMyPosh -Force:$Force
Initialize-OhMyPosh
Set-GitAliases -Force:$Force

Write-Host 'Terminal setup complete.'
