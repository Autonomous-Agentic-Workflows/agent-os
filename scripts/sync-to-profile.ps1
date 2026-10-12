#requires -Version 7.0
<#
.SYNOPSIS
    Sync project standards back to a base Agent OS profile for reuse.

.DESCRIPTION
    Windows-native (PowerShell 7) port of scripts/sync-to-profile.sh.

    Reads <project>/agent-os/standards, lets you pick files (or -All), and copies
    them into <agent-os>/profiles/<profile>/standards. Existing files are backed
    up to the profile's standards/.backups/<timestamp>/ before being overwritten.

    Run this from the project directory you want to sync from.

.PARAMETER Profile
    Target profile. A missing profile prompts for creation (or is created
    automatically when -Force is also supplied).

.PARAMETER NewProfile
    Create a new profile with these standards.

.PARAMETER All
    Sync all standards (skip the interactive file selection).

.PARAMETER Overwrite
    Overwrite existing files without prompting (a backup is still taken).

.PARAMETER Force
    Do not prompt for confirmations (used with -Profile or -NewProfile).

.EXAMPLE
    pwsh -File scripts/sync-to-profile.ps1 -Profile recovery -All -Overwrite

.EXAMPLE
    pwsh -File scripts/sync-to-profile.ps1 -NewProfile nextjs -All
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Profile,
    [string]$NewProfile,
    [switch]$All,
    [switch]$Overwrite,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$script:ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:BaseDir    = Split-Path -Parent $script:ScriptDir
$script:ProjectDir = (Get-Location).Path

function Write-Section([string]$Text) { Write-Host ''; Write-Host "=== $Text ===" -ForegroundColor Cyan; Write-Host '' }
function Write-Status ([string]$Text) { Write-Host $Text -ForegroundColor Cyan }
function Write-Ok     ([string]$Text) { Write-Host "[ok] $Text" -ForegroundColor Green }
function Write-Warn   ([string]$Text) { Write-Host "[!]  $Text" -ForegroundColor Yellow }
function Write-Err    ([string]$Text) { Write-Host "[x]  $Text" -ForegroundColor Red }

function Get-StandardsFiles {
    param([string]$StandardsDir)
    Get-ChildItem -LiteralPath $StandardsDir -Recurse -File -Filter *.md |
        Where-Object { $_.FullName -notmatch '\\\.backups\\' } |
        ForEach-Object { $_.FullName.Substring($StandardsDir.Length).TrimStart('\', '/') } |
        Sort-Object
}

function New-Profile([string]$Name) {
    $dir = Join-Path $script:BaseDir "profiles/$Name/standards"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Ok "Created profile: $Name"
}

function Backup-Files {
    param([string]$ProfileName, [string[]]$Files)
    if (-not $Files -or $Files.Count -eq 0) { return }
    $profileStandards = Join-Path $script:BaseDir "profiles/$ProfileName/standards"
    $stamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $backupDir = Join-Path $profileStandards ".backups/$stamp"
    $count = 0
    foreach ($rel in $Files) {
        $src = Join-Path $profileStandards $rel
        if (Test-Path -LiteralPath $src) {
            $dst = Join-Path $backupDir $rel
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
            Copy-Item -LiteralPath $src -Destination $dst -Force
            $count++
        }
    }
    if ($count -gt 0) { Write-Ok "Backed up $count file(s) to .backups/$stamp/" }
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
Write-Section 'Agent OS Sync to Profile'

$profilesDir = Join-Path $script:BaseDir 'profiles'
$standardsDir = Join-Path $script:ProjectDir 'agent-os/standards'

if (-not (Test-Path -LiteralPath $profilesDir)) { Write-Err 'No profiles directory in base installation.'; exit 1 }
if (-not (Test-Path -LiteralPath $standardsDir)) {
    Write-Err 'No standards directory found at agent-os/standards/.'
    Write-Host ''
    Write-Host 'Run project-install.ps1 first to set up Agent OS in this project.'
    exit 1
}

$files = @(Get-StandardsFiles -StandardsDir $standardsDir)
if ($files.Count -eq 0) {
    Write-Err 'No standards to sync. Create standards first using /discover-standards or manually.'
    exit 1
}

# --- resolve target profile ---
if ($NewProfile) {
    $Profile = $NewProfile
    if (-not (Test-Path -LiteralPath (Join-Path $profilesDir $Profile))) { New-Profile $Profile }
}
elseif ($Profile) {
    if (-not (Test-Path -LiteralPath (Join-Path $profilesDir $Profile))) {
        $create = $Force -or ((Read-Host "Profile '$Profile' doesn't exist. Create it? (y/N)") -match '^[Yy]')
        if ($create) { New-Profile $Profile } else { Write-Err 'Cancelled.'; exit 1 }
    }
}
else {
    $available = @(Get-ChildItem -LiteralPath $profilesDir -Directory | Select-Object -ExpandProperty Name | Sort-Object)
    Write-Host ''
    Write-Status 'Available profiles:'
    $i = 1
    foreach ($name in $available) { Write-Host "  $i) $name"; $i++ }
    Write-Host "  $i) [Create new profile]"
    $max = $i
    do {
        $choice = Read-Host "Select profile (1-$max)"
    } while (-not ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $max))
    if ([int]$choice -eq $max) {
        $Profile = Read-Host 'Enter new profile name'
        if (-not $Profile) { Write-Err 'Profile name cannot be empty.'; exit 1 }
        if (-not (Test-Path -LiteralPath (Join-Path $profilesDir $Profile))) { New-Profile $Profile }
    }
    else {
        $Profile = $available[[int]$choice - 1]
    }
}

# --- select files ---
if ($All) {
    $selected = @($files)
}
else {
    $sel = @{}
    foreach ($f in $files) { $sel[$f] = $true }
    while ($true) {
        Write-Host ''
        Write-Status 'Select standards to sync:'
        $i = 1
        foreach ($f in $files) {
            $mark = if ($sel[$f]) { 'x' } else { ' ' }
            Write-Host ("  {0}) [{1}] {2}" -f $i, $mark, $f)
            $i++
        }
        Write-Host ''
        Write-Host '  Enter number to toggle   a) All   n) None   d) Done'
        $choice = Read-Host "Toggle (1-$($files.Count)), a, n, or d"
        switch -Regex ($choice) {
            '^[aA]$' { foreach ($f in $files) { $sel[$f] = $true } }
            '^[nN]$' { foreach ($f in $files) { $sel[$f] = $false } }
            '^[dD]$' { break }
            '^\d+$' {
                $idx = [int]$choice - 1
                if ($idx -ge 0 -and $idx -lt $files.Count) { $sel[$files[$idx]] = -not $sel[$files[$idx]] }
            }
        }
        if ($choice -match '^[dD]$') { break }
    }
    $selected = @($files | Where-Object { $sel[$_] })
}

if ($selected.Count -eq 0) { Write-Err 'No files selected.'; exit 1 }

# --- resolve conflicts ---
$profileStandards = Join-Path $script:BaseDir "profiles/$Profile/standards"
$conflicts = @($selected | Where-Object { Test-Path -LiteralPath (Join-Path $profileStandards $_) })

if ($conflicts.Count -gt 0) {
    if ($Overwrite -or $Force) {
        Backup-Files -ProfileName $Profile -Files $conflicts
    }
    else {
        Write-Host ''
        Write-Warn "$($conflicts.Count) file(s) already exist in profile '$Profile':"
        foreach ($c in $conflicts) { Write-Host "    - $c" }
        $done = $false
        while (-not $done) {
            Write-Host ''
            Write-Host '  1) Overwrite all (with backup)'
            Write-Host '  2) Skip existing files'
            Write-Host '  3) Cancel'
            switch (Read-Host 'Choice (1-3)') {
                '1' { Backup-Files -ProfileName $Profile -Files $conflicts; $done = $true }
                '2' { $selected = @($selected | Where-Object { $conflicts -notcontains $_ }); $done = $true }
                '3' { Write-Err 'Cancelled.'; exit 1 }
            }
        }
        if ($selected.Count -eq 0) { Write-Warn 'No files left to sync after skipping conflicts.'; exit 0 }
    }
}

Write-Host ''
Write-Status 'Sync summary:'
Write-Host "  Profile: $Profile"
Write-Host "  Files to sync: $($selected.Count)"

if (-not $PSCmdlet.ShouldProcess("profile '$Profile'", "Sync $($selected.Count) standards file(s)")) { exit 0 }

$synced = 0
foreach ($rel in $selected) {
    $src = Join-Path $standardsDir $rel
    $dst = Join-Path $profileStandards $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $synced++
}

Write-Host ''
Write-Ok "Synced $synced file(s) to profile '$Profile'"
Write-Host ''
