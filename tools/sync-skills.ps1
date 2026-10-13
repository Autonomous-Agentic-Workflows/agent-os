#!/usr/bin/env pwsh
# sync-skills.ps1 - refresh the central skills/ from the source tool repos.
# Copies (not links) so skills load even when source repos are absent.
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..\skills'
$root = [System.IO.Path]::GetFullPath($root)

$map = [ordered]@{
  'frontend-design'               = 'D:\StudioProjects\memory-palace-with-brain\.agents\skills\frontend-design'
  'integration-nextjs-app-router' = 'D:\StudioProjects\memory-palace-with-brain\.claude\skills\integration-nextjs-app-router'
  'design-guide'                  = 'D:\StudioProjects\paperclip-autonomous-agents\.claude\skills\design-guide'
  'paperclip-task-bridge'         = 'D:\StudioProjects\paperclip-autonomous-agents\packages\adapters\hermes\skills\paperclip-task-bridge'
}

New-Item -ItemType Directory -Force $root | Out-Null
foreach ($k in $map.Keys) {
  $src = $map[$k]
  $dst = Join-Path $root $k
  if (-not (Test-Path $src)) { Write-Warning "skip $k (source missing: $src)"; continue }
  if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
  Copy-Item $src $dst -Recurse -Force
  Write-Host "synced $k"
}
