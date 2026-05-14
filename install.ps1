#Requires -Version 7.0

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

function Set-ManagedFileContent {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Content,
        [Parameter(Mandatory)]
        [string]$Label,
        [Parameter(Mandatory)]
        [ValidateSet('Keep', 'Append', 'Override')]
        [string]$OnExists,
        [switch]$SkipIfExactMatch,
        [switch]$SkipIfContains
    )

    $targetDir = Split-Path -Path $Path -Parent
    if ($targetDir) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $newContent = $Content.Trim()
    $isJsonFile = $Path -match '\.json$'

    if (Test-Path $Path) {
        $existingContent = Get-Content -Path $Path -Raw

        if ($SkipIfContains -and $existingContent -and $existingContent.Contains($newContent)) {
            Write-Host "$Label already contains the configuration. Skipping."
            return
        }

        if ($SkipIfExactMatch -and $existingContent -and $existingContent.Trim() -eq $newContent) {
            Write-Host "$Label already matches remote content. Skipping."
            return
        }

        switch ($OnExists) {
            'Keep' {
                Write-Host "$Label already exists. Keeping existing file: $Path"
                return
            }
            'Append' {
                Write-Host "Appending to existing $($Label): $Path"

                if ($isJsonFile) {
                    try {
                        $existingJson = $existingContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                        $newJson = $newContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop

                        foreach ($key in $newJson.Keys) {
                            $existingJson[$key] = $newJson[$key]
                        }

                        $mergedContent = $existingJson | ConvertTo-Json -Depth 100
                        Set-Content -Path $Path -Value $mergedContent -NoNewline
                        Write-Host "$Label merged successfully: $Path"
                    }
                    catch {
                        Write-Warning "Failed to merge JSON content: $_"
                        Write-Host "Falling back to simple append."
                        Add-Content -Path $Path -Value "`n$Content"
                    }
                }
                else {
                    Add-Content -Path $Path -Value "`n$Content"
                }

                Write-Host "$Label configured: $Path"
                return
            }
            'Override' {
                Write-Host "Overriding existing $($Label): $Path"
            }
        }
    }

    Set-Content -Path $Path -Value $Content -NoNewline
    Write-Host "$Label configured: $Path"
}

# Loads and validates remote copy config from a JSON file.
# Returns a hashtable with RepoUrl, Branch, and Mappings (validated PSCustomObject entries).
function Get-RemoteRepoConfig {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Remote copy config not found: $ConfigPath"
    }

    $json = Get-Content -Path $ConfigPath -Raw
    try {
        $config = $json | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Failed to parse remote copy config JSON: $_"
    }

    if (-not $config.PSObject.Properties['repoUrl'] -or -not $config.repoUrl) {
        throw "Config missing required field: repoUrl"
    }
    if (-not $config.PSObject.Properties['branch'] -or -not $config.branch) {
        throw "Config missing required field: branch"
    }

    $validMappings = @()
    if ($config.PSObject.Properties['mappings'] -and $config.mappings) {
        foreach ($mapping in $config.mappings) {
            $hasSource = $mapping.PSObject.Properties['source'] -and $mapping.source
            $hasTarget = $mapping.PSObject.Properties['target'] -and $mapping.target
            if (-not $hasSource -or -not $hasTarget) {
                Write-Warning "Skipping invalid mapping entry (missing source or target): $($mapping | ConvertTo-Json -Compress)"
                continue
            }
            $validMappings += $mapping
        }
    }

    return @{
        RepoUrl  = $config.repoUrl
        Branch   = $config.branch
        Mappings = $validMappings
    }
}

# Normalizes path separators and expands {HOME}, {PROFILE}, {WORKSPACE_ROOT} placeholders in targets.
# Returns an array of hashtables with canonical Source, Target, Label, SkipIfExactMatch, SkipIfContains.
function Resolve-MappingPaths {
    param(
        [array]$Mappings,
        [string]$WorkspaceRoot
    )

    $profilePath = ($PROFILE.CurrentUserAllHosts) -replace '\\', '/'
    $homePath = $HOME -replace '\\', '/'
    $wsPath = $WorkspaceRoot -replace '\\', '/'

    $resolved = @()
    foreach ($m in $Mappings) {
        $source = ($m.source -replace '\\', '/').TrimStart('/')
        $target = ($m.target -replace '\\', '/') `
            -replace '\{PROFILE\}', $profilePath `
            -replace '\{HOME\}', $homePath `
            -replace '\{WORKSPACE_ROOT\}', $wsPath

        $label = if ($m.PSObject.Properties['label'] -and $m.label) { $m.label }            else { $source }
        $skipExact = if ($m.PSObject.Properties['skipIfExactMatch'] -and $m.skipIfExactMatch) { [bool]$m.skipIfExactMatch } else { $false }
        $skipContains = if ($m.PSObject.Properties['skipIfContains'] -and $m.skipIfContains) { [bool]$m.skipIfContains }   else { $false }

        $resolved += @{
            Source           = $source
            Target           = $target
            Label            = $label
            SkipIfExactMatch = $skipExact
            SkipIfContains   = $skipContains
        }
    }
    return $resolved
}

# Performs a shallow git clone of the given branch into TargetDir.
function Invoke-GitShallowClone {
    param(
        [Parameter(Mandatory)] [string]$RepoUrl,
        [Parameter(Mandatory)] [string]$Branch,
        [Parameter(Mandatory)] [string]$TargetDir
    )

    Write-Host "Cloning $RepoUrl (branch: $Branch)..."
    $startTime = Get-Date

    $output = git clone --depth 1 --branch $Branch $RepoUrl $TargetDir 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed (exit $LASTEXITCODE): $output"
    }

    $elapsed = (Get-Date) - $startTime
    Write-Host "Clone complete in $($elapsed.TotalSeconds.ToString('F1'))s."
}

# Returns relative (forward-slash) paths for all non-.git files under CloneDir.
function Get-ClonedRepoFiles {
    param(
        [Parameter(Mandatory)] [string]$CloneDir
    )

    $gitDir = Join-Path $CloneDir '.git'
    $prefixLen = $CloneDir.TrimEnd([System.IO.Path]::DirectorySeparatorChar, '/').Length + 1

    Get-ChildItem -Path $CloneDir -Recurse -File -Force |
    Where-Object { $_.FullName -notlike "$gitDir*" } |
    ForEach-Object { ($_.FullName.Substring($prefixLen)) -replace '\\', '/' }
}

# Resolves the local target path for a single remote-relative file path.
# Precedence: exact file mapping > mapped-folder inheritance > fallback repo-root-relative.
function Resolve-RemoteFilePath {
    param(
        [Parameter(Mandatory)] [string]$RelativePath,
        [array]  $Mappings,
        [Parameter(Mandatory)] [string]$LocalRoot
    )

    $normPath = $RelativePath -replace '\\', '/'

    # 1. Exact file mapping
    foreach ($m in $Mappings) {
        if ($m.Source -eq $normPath) {
            return @{ Target = $m.Target; Mapping = $m; Mode = 'exact' }
        }
    }

    # 2. Mapped-folder inheritance: file is under a mapped source folder
    foreach ($m in $Mappings) {
        $folderPrefix = $m.Source.TrimEnd('/') + '/'
        if ($normPath.StartsWith($folderPrefix)) {
            $subPath = $normPath.Substring($folderPrefix.Length)
            $target = $m.Target.TrimEnd('/') + '/' + $subPath
            return @{ Target = $target; Mapping = $m; Mode = 'folder' }
        }
    }

    # 3. Fallback: preserve repo-root-relative path under local root
    $localRootNorm = $LocalRoot -replace '\\', '/'
    $target = $localRootNorm.TrimEnd('/') + '/' + $normPath
    return @{ Target = $target; Mapping = $null; Mode = 'fallback' }
}

# Clones a remote repository and copies all files to local targets according to JSON config rules.
# Collision behavior: 'Warn' continues after logging; 'Fail' throws before any writes.
# Temporary clone directory is always removed via try/finally.
function Copy-RemoteRepoContent {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        [Parameter(Mandatory)]
        [string]$LocalRoot,
        [ValidateSet('Keep', 'Append', 'Override')]
        [string]$OnExists = 'Append',
        [ValidateSet('Warn', 'Fail')]
        [string]$CollisionBehavior = 'Warn'
    )

    $config = Get-RemoteRepoConfig -ConfigPath $ConfigPath
    $mappings = Resolve-MappingPaths -Mappings $config.Mappings -WorkspaceRoot $LocalRoot

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())

    try {
        Invoke-GitShallowClone -RepoUrl $config.RepoUrl -Branch $config.Branch -TargetDir $tempDir

        Write-Host 'Discovering remote repository files...'
        $startTime = Get-Date
        $remoteFiles = @(Get-ClonedRepoFiles -CloneDir $tempDir)
        $elapsed = (Get-Date) - $startTime
        Write-Host "Discovered $($remoteFiles.Count) file(s) in $($elapsed.TotalSeconds.ToString('F1'))s."

        # Build resolution map and detect target collisions before writing
        $resolutionMap = [ordered]@{}
        foreach ($relPath in $remoteFiles) {
            $resolution = Resolve-RemoteFilePath -RelativePath $relPath -Mappings $mappings -LocalRoot $LocalRoot
            $targetPath = $resolution.Target

            if ($resolutionMap.Contains($targetPath)) {
                $msg = "Target collision: '$relPath' and '$($resolutionMap[$targetPath].Source)' both resolve to '$targetPath'."
                if ($CollisionBehavior -eq 'Fail') {
                    throw $msg
                }
                Write-Warning $msg
                continue
            }

            $resolutionMap[$targetPath] = @{
                Source     = $relPath
                Resolution = $resolution
            }
        }

        Write-Host "Copying $($resolutionMap.Count) file(s)..."
        foreach ($targetPath in $resolutionMap.Keys) {
            $entry = $resolutionMap[$targetPath]
            $sourcePath = Join-Path $tempDir ($entry.Source -replace '/', [System.IO.Path]::DirectorySeparatorChar)
            $content = Get-Content -Path $sourcePath -Raw
            if ($null -eq $content) { $content = '' }

            $mapping = $entry.Resolution.Mapping
            $mode = $entry.Resolution.Mode
            $label = if ($null -ne $mapping -and $mapping.Label) { $mapping.Label }            else { $entry.Source }
            $skipExact = if ($null -ne $mapping -and $mapping.SkipIfExactMatch) { $mapping.SkipIfExactMatch } else { $false }
            $skipContains = if ($null -ne $mapping -and $mapping.SkipIfContains) { $mapping.SkipIfContains }   else { $false }

            Write-Host "  [$mode] $($entry.Source) -> $targetPath"

            Set-ManagedFileContent -Path $targetPath -Content $content -Label $label `
                -OnExists $OnExists -SkipIfExactMatch:$skipExact -SkipIfContains:$skipContains
        }
    }
    finally {
        if (Test-Path $tempDir) {
            Write-Host 'Cleaning up temporary clone directory...'
            Remove-Item -Recurse -Force $tempDir
            Write-Host 'Cleanup complete.'
        }
    }
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


$RemoteCopyConfigPath = Join-Path $PSScriptRoot 'remote-copy-config.json'
$WorkspaceRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

Write-Host "Existing file action: $ExistingFileAction"
Install-OhMyPosh

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    throw 'Oh My Posh was not found after installation.'
}

Copy-RemoteRepoContent -ConfigPath $RemoteCopyConfigPath -LocalRoot $WorkspaceRoot -OnExists $ExistingFileAction

foreach ($pkg in @('opencode-ai', '@anthropic-ai/claude-code', '@fission-ai/openspec', '@neuralnomads/codenomad')) {
    npm list -g $pkg --depth 0 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "$pkg already installed. Skipping." ; continue }
    npm install -g $pkg
}


if ($DevContainer) {
    Write-Host 'Devcontainer terminal setup complete.'
}
else {
    Write-Host 'Terminal setup complete.'
}
