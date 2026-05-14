#Requires -Version 7.0

<#
.SYNOPSIS
    Installs development tools (Oh My Posh, npm packages) and optionally copies dotfiles.

.PARAMETER Force
    Forces reinstallation of tools even if they already exist.

.PARAMETER DevContainer
    Indicates this is running in a devcontainer environment.

.PARAMETER ExistingFileAction
    Action to take when a dotfile already exists: Keep, Append, or Override.

.EXAMPLE
    .\install.ps1
    Installs tools and copies dotfiles with Append behavior.

.EXAMPLE
    .\install.ps1 -Force -ExistingFileAction Override
    Reinstalls all tools and overrides existing dotfiles.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DevContainer,
    [ValidateSet('Keep', 'Append', 'Override')]
    [string]$ExistingFileAction = 'Append'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Force) {
    if ($PSBoundParameters.ContainsKey('ExistingFileAction') -and $ExistingFileAction -ne 'Override') {
        throw '-Force cannot be combined with -ExistingFileAction Keep or Append.'
    }

    $ExistingFileAction = 'Override'
}

function Install-OhMyPoshDependencies {
    Write-Host 'Ensuring Oh My Posh dependencies are installed...'

    if ($IsWindows) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'winget is required to install Oh My Posh on Windows but was not found.'
        }

        Write-Host 'Windows dependency checks complete.'
        return
    }

    $packageManagers = @(
        @{ Name = 'apt-get'; Install = 'sudo apt-get update && sudo apt-get install -y curl unzip ca-certificates fontconfig' }
        @{ Name = 'dnf'; Install = 'sudo dnf install -y curl unzip ca-certificates fontconfig' }
        @{ Name = 'yum'; Install = 'sudo yum install -y curl unzip ca-certificates fontconfig' }
        @{ Name = 'pacman'; Install = 'sudo pacman -Sy --noconfirm curl unzip ca-certificates fontconfig' }
        @{ Name = 'zypper'; Install = 'sudo zypper --non-interactive install curl unzip ca-certificates fontconfig' }
        @{ Name = 'apk'; Install = 'sudo apk add --no-cache curl unzip ca-certificates fontconfig' }
    )

    foreach ($manager in $packageManagers) {
        if (Get-Command $manager.Name -ErrorAction SilentlyContinue) {
            Write-Host "Installing dependencies with $($manager.Name)..."
            bash -lc $manager.Install
            Write-Host 'Dependency installation complete.'
            return
        }
    }

    throw 'No supported package manager found. Install curl, unzip, ca-certificates, and fontconfig manually.'
}

function Install-OhMyPosh {
    Install-OhMyPoshDependencies

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

function Install-NpmPackages {
    Write-Host 'Installing npm packages...' -ForegroundColor Cyan

    $npmPackages = @(
        'opencode-ai'
        '@anthropic-ai/claude-code'
        '@fission-ai/openspec'
        '@neuralnomads/codenomad'
    )

    foreach ($pkg in $npmPackages) {
        if (-not $Force) {
            npm list -g $pkg --depth 0 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$pkg already installed. Skipping."
                continue
            }
        }

        Write-Host "Installing $pkg..."
        npm install -g $pkg
    }

    Write-Host 'npm packages installation complete.' -ForegroundColor Green
}

# Main execution
Write-Host "Existing file action: $ExistingFileAction" -ForegroundColor Cyan
Write-Host ''

# Install Oh My Posh
Write-Host 'Installing Oh My Posh...' -ForegroundColor Cyan
Install-OhMyPosh

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    throw 'Oh My Posh was not found after installation.'
}
Write-Host 'Oh My Posh installation complete.' -ForegroundColor Green
Write-Host ''

# Install npm packages
Install-NpmPackages
Write-Host ''

# Copy dotfiles to their target locations
Write-Host 'Copying dotfiles to system locations...' -ForegroundColor Cyan

$dotfiles = @(
    @{
        Source = Join-Path $PSScriptRoot 'Microsoft.VSCode_profile.ps1'
        Target = $PROFILE.CurrentUserAllHosts
        Label  = 'PowerShell Profile'
    }
    @{
        Source = Join-Path $PSScriptRoot '.gitconfig'
        Target = Join-Path $HOME '.gitconfig'
        Label  = 'Git Config'
    }
)

foreach ($dotfile in $dotfiles) {
    if (-not (Test-Path $dotfile.Source)) {
        Write-Warning "$($dotfile.Label) not found at: $($dotfile.Source)"
        continue
    }

    $targetDir = Split-Path -Path $dotfile.Target -Parent
    if ($targetDir -and -not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $sourceContent = Get-Content -Path $dotfile.Source -Raw

    if (Test-Path $dotfile.Target) {
        $existingContent = Get-Content -Path $dotfile.Target -Raw

        switch ($ExistingFileAction) {
            'Keep' {
                Write-Host "$($dotfile.Label) already exists. Keeping existing file: $($dotfile.Target)"
                continue
            }
            'Append' {
                if ($existingContent -and $existingContent.Contains($sourceContent.Trim())) {
                    Write-Host "$($dotfile.Label) already contains the configuration. Skipping."
                    continue
                }
                Write-Host "Appending to existing $($dotfile.Label): $($dotfile.Target)"
                Add-Content -Path $dotfile.Target -Value "`n$sourceContent"
                Write-Host "$($dotfile.Label) configured: $($dotfile.Target)"
                continue
            }
            'Override' {
                Write-Host "Overriding existing $($dotfile.Label): $($dotfile.Target)"
            }
        }
    }

    Copy-Item -Path $dotfile.Source -Destination $dotfile.Target -Force
    Write-Host "$($dotfile.Label) copied: $($dotfile.Target)"
}

Write-Host 'Dotfiles copy complete.' -ForegroundColor Green
Write-Host ''

# Final message
if ($DevContainer) {
    Write-Host 'Devcontainer setup complete!' -ForegroundColor Green
}
else {
    Write-Host 'Setup complete!' -ForegroundColor Green
}
