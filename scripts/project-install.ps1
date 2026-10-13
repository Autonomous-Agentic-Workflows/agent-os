#requires -Version 7.0
<#
.SYNOPSIS
    Install Agent OS into the current project directory.

.DESCRIPTION
    Windows-native (PowerShell 7) port of scripts/project-install.sh. The bash
    installer cannot run on hosts where bash/WSL is unavailable.

    Copies the requested profile's standards (honoring the inheritance chain in
    config.yml) into <project>/agent-os/standards, regenerates
    <project>/agent-os/standards/index.yml (seeded from the repo's
    standards-index.yml), and installs the Agent OS commands into
    <project>/.claude/commands/agent-os.

    Run this from the project directory you want to install into.

.PARAMETER Profile
    Profile to install. Defaults to `default_profile` from config.yml.

.PARAMETER Project
    Project directory to install into. Defaults to the current directory.
    Lets you run the installer from anywhere (including the base dir).

.PARAMETER CommandsOnly
    Update commands only; leave existing standards untouched.

.PARAMETER Force
    Skip the interactive overwrite confirmation.

.EXAMPLE
    pwsh -File scripts/project-install.ps1 -Profile recovery -Project D:\StudioProjects\MasterRecovery3

.EXAMPLE
    pwsh -File scripts/project-install.ps1 -CommandsOnly
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Profile,
    [string]$Project,
    [switch]$CommandsOnly,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$script:ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:BaseDir    = Split-Path -Parent $script:ScriptDir
$script:ProjectDir = if ($Project) { (Resolve-Path -LiteralPath $Project -ErrorAction Stop).Path } else { (Get-Location).Path }

# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------
function Write-Section([string]$Text) { Write-Host ''; Write-Host "=== $Text ===" -ForegroundColor Cyan; Write-Host '' }
function Write-Status ([string]$Text) { Write-Host $Text -ForegroundColor Cyan }
function Write-Ok     ([string]$Text) { Write-Host "[ok] $Text" -ForegroundColor Green }
function Write-Warn   ([string]$Text) { Write-Host "[!]  $Text" -ForegroundColor Yellow }
function Write-Err    ([string]$Text) { Write-Host "[x]  $Text" -ForegroundColor Red }

# -----------------------------------------------------------------------------
# config.yml helpers (minimal YAML: default_profile + profile inheritance)
# -----------------------------------------------------------------------------
function Get-ConfigValue {
    param([string]$Path, [string]$Key, [string]$Default)
    if (-not (Test-Path -LiteralPath $Path)) { return $Default }
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match ("^" + [regex]::Escape($Key) + ":\s*(.*?)\s*$")) {
            if ($Matches[1]) { return $Matches[1] }
        }
    }
    return $Default
}

function Get-ProfileParentMap {
    param([string]$Path)
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $map }
    $inProfiles = $false
    $current = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^profiles:\s*$') { $inProfiles = $true; $current = $null; continue }
        if ($line -match '^[A-Za-z].*:') { $inProfiles = $false; $current = $null; continue }
        if (-not $inProfiles) { continue }
        if ($line -match '^  ([A-Za-z0-9_-]+):\s*(#.*)?$') {
            $current = $Matches[1]
            if (-not $map.ContainsKey($current)) { $map[$current] = '' }
            continue
        }
        if ($current -and $line -match '^\s+inherits_from:\s*([A-Za-z0-9_-]+)\s*$') {
            $map[$current] = $Matches[1]
        }
    }
    return $map
}

function Get-InheritanceChain {
    param([hashtable]$ParentMap, [string]$Name, [string]$ProfilesDir)
    $chain = @()
    $seen = @()
    $current = $Name
    while ($current) {
        if ($seen -contains $current) {
            throw "Circular dependency in profile inheritance: $($seen -join ' -> ') -> $current"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $ProfilesDir $current))) {
            $suffix = if ($current -ne $Name) { ' (referenced by inheritance chain)' } else { '' }
            throw "Profile not found: $current$suffix"
        }
        $seen += $current
        $chain = ,$current + $chain   # prepend => base profile first
        $current = if ($ParentMap.ContainsKey($current)) { $ParentMap[$current] } else { '' }
    }
    return $chain
}

# -----------------------------------------------------------------------------
# index.yml helpers
# -----------------------------------------------------------------------------
function Read-IndexMap {
    param([string]$Path)
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $map }
    $folder = $null; $file = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*#') { continue }
        if ($line -match '^([A-Za-z0-9_-]+):\s*$') {
            $folder = $Matches[1]; $file = $null
            if (-not $map.ContainsKey($folder)) { $map[$folder] = @{} }
            continue
        }
        if ($folder -and $line -match '^  ([A-Za-z0-9_.-]+):\s*$') { $file = $Matches[1]; continue }
        if ($folder -and $file -and $line -match '^\s+description:\s*(.+?)\s*$') {
            $map[$folder][$file] = $Matches[1]; $file = $null
        }
    }
    return $map
}

function Write-StandardsIndex {
    param([string]$StandardsDir, [hashtable]$Seed)
    $indexFile = Join-Path $StandardsDir 'index.yml'
    $existing = Read-IndexMap -Path $indexFile

    $files = Get-ChildItem -LiteralPath $StandardsDir -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\\.backups\\' }

    $groups = @{}
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($StandardsDir.Length).TrimStart('\', '/')
        $parts = $rel -split '[\\/]'
        $folder = if ($parts.Count -gt 1) { $parts[0] } else { 'root' }
        $name = [IO.Path]::GetFileNameWithoutExtension($f.Name)
        if (-not $groups.ContainsKey($folder)) { $groups[$folder] = New-Object System.Collections.Generic.List[string] }
        $groups[$folder].Add($name)
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Agent OS Standards Index'); $lines.Add('')
    $entries = 0; $newCount = 0
    foreach ($folder in ($groups.Keys | Sort-Object)) {
        $lines.Add("${folder}:")
        foreach ($name in ($groups[$folder] | Sort-Object)) {
            $desc = $null
            if ($Seed.ContainsKey($folder) -and $Seed[$folder].ContainsKey($name)) {
                $desc = $Seed[$folder][$name]
            }
            elseif ($existing.ContainsKey($folder) -and $existing[$folder].ContainsKey($name) -and
                    $existing[$folder][$name] -ne 'Needs description - run /index-standards') {
                $desc = $existing[$folder][$name]
            }
            if (-not $desc) { $desc = 'Needs description - run /index-standards'; $newCount++ }
            $lines.Add("  ${name}:")
            $lines.Add("    description: $desc")
            $entries++
        }
        $lines.Add('')
    }
    Set-Content -LiteralPath $indexFile -Value ($lines -join "`n") -Encoding utf8
    return [pscustomobject]@{ Entries = $entries; New = $newCount }
}

# -----------------------------------------------------------------------------
# Install steps
# -----------------------------------------------------------------------------
function Install-Standards {
    param([string[]]$Chain)
    Write-Status 'Installing standards...'
    $projectStandards = Join-Path $script:ProjectDir 'agent-os/standards'
    New-Item -ItemType Directory -Force -Path $projectStandards | Out-Null

    $sources = [ordered]@{}
    foreach ($profileName in $Chain) {
        $profileStandards = Join-Path $script:BaseDir "profiles/$profileName/standards"
        if (-not (Test-Path -LiteralPath $profileStandards)) { continue }
        foreach ($file in (Get-ChildItem -LiteralPath $profileStandards -Recurse -File -Filter *.md |
                           Where-Object { $_.FullName -notmatch '\\\.backups\\' })) {
            $rel  = $file.FullName.Substring($profileStandards.Length).TrimStart('\', '/')
            $dest = Join-Path $projectStandards $rel
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
            $sources[$rel] = $profileName
        }
    }

    foreach ($rel in ($sources.Keys | Sort-Object)) {
        if ($Chain.Count -gt 1) { Write-Host "  $rel (from $($sources[$rel]))" } else { Write-Host "  $rel" }
    }
    $total = $sources.Keys.Count
    if ($total -gt 0) { Write-Ok "Installed $total standards files" }
    else { Write-Ok 'No standards to install (profile is empty)' }
}

function Install-Commands {
    Write-Status 'Installing commands...'
    $src  = Join-Path $script:BaseDir 'commands/agent-os'
    $dest = Join-Path $script:ProjectDir '.claude/commands/agent-os'
    if (-not (Test-Path -LiteralPath $src)) { Write-Warn 'No commands found in base installation'; return }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $count = 0
    foreach ($file in Get-ChildItem -LiteralPath $src -File -Filter *.md) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $dest $file.Name) -Force
        $count++
    }
    Write-Ok "Installed $count commands to .claude/commands/agent-os/"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
Write-Section 'Agent OS Project Installation'

if ($script:ProjectDir -eq $script:BaseDir) {
    Write-Err 'Cannot install Agent OS into the base installation directory. Navigate to a project directory first.'
    exit 1
}
$configPath = Join-Path $script:BaseDir 'config.yml'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Err 'Base installation config.yml not found.'
    exit 1
}

$defaultProfile = Get-ConfigValue -Path $configPath -Key 'default_profile' -Default 'default'
$effProfile     = if ($Profile) { $Profile } else { $defaultProfile }
$profilesDir    = Join-Path $script:BaseDir 'profiles'
$parents        = Get-ProfileParentMap -Path $configPath

try { $chain = @(Get-InheritanceChain -ParentMap $parents -Name $effProfile -ProfilesDir $profilesDir) }
catch { Write-Err $_.Exception.Message; exit 1 }

Write-Host ''
Write-Status 'Configuration:'
Write-Host "  Profile: $effProfile"
if ($chain.Count -gt 1) { Write-Host "  Inheritance: $($chain -join ' -> ')" }
Write-Host "  Commands only: $([bool]$CommandsOnly)"

if (-not $CommandsOnly) {
    $existing = Join-Path $script:ProjectDir 'agent-os/standards'
    if ((Test-Path -LiteralPath $existing) -and -not $Force) {
        Write-Host ''
        Write-Warn "Existing standards folder detected at: $existing"
        Write-Host "This will overwrite existing standards with those from the '$effProfile' profile."
        $ans = Read-Host 'Continue? (y/N)'
        if ($ans -notmatch '^[Yy]') {
            Write-Host ''
            Write-Host 'Installation cancelled.'
            Write-Host 'To update only commands without touching standards, re-run with -CommandsOnly.'
            exit 0
        }
    }
}

if (-not $PSCmdlet.ShouldProcess($script:ProjectDir, "Install Agent OS profile '$effProfile'")) { exit 0 }

if (-not $CommandsOnly) {
    Install-Standards -Chain $chain
    Write-Status 'Updating standards index...'
    $seed = Read-IndexMap -Path (Join-Path $script:BaseDir 'standards-index.yml')
    $res  = Write-StandardsIndex -StandardsDir (Join-Path $script:ProjectDir 'agent-os/standards') -Seed $seed
    Write-Ok "Updated index.yml ($($res.Entries) entries, $($res.New) needing description)"
}
else {
    Write-Status 'Skipping standards (-CommandsOnly)'
}

Install-Commands

Write-Host ''
Write-Ok 'Agent OS installed successfully!'
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Run /discover-standards to extract patterns from your codebase'
Write-Host '  2. Run /inject-standards to inject standards into your context'
Write-Host ''
