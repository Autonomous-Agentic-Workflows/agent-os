# PowerShell Safety Standards

## Destructive Operations

- `-WhatIf` / `-Confirm` support via `SupportsShouldProcess` for anything that deletes, moves, or overwrites
- Verify target existence before `Remove-Item` - never blind-delete on wildcards wider than intended
- Test against sample data before running against real volumes (D:\ is the data volume; S:\ is legacy)

## Error Handling

- `$ErrorActionPreference = 'Stop'` at script top when failures must halt, or per-call `-ErrorAction Stop` - never swallow errors silently
- `try/catch` around external calls (network, disk, other processes); log `$_.Exception.Message`, not just `$_.Exception`
- Exit with meaningful codes: respect `$LASTEXITCODE` for native commands

## Secrets & Tokens

- Never hardcode tokens in scripts - read from environment variables or a vault
- Scripts containing tokens must not be committed; keep them out of the repo via `.gitignore`

## Execution

- Scripts must run under the user's standard execution policy - do not rely on `Set-ExecutionPolicy -Force` machine changes
- Prefer `pwsh` (PowerShell 7) over bundled `powershell.exe` (5.1) unless legacy compatibility is required
