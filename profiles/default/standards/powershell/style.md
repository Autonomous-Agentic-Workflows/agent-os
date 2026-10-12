# PowerShell Style Standards

## Naming

- Use **approved verbs** for all functions and scripts (`Get-`, `Set-`, `New-`, `Remove-`, `Test-`, `Convert-`, `Invoke-`) - check with `Get-Verb`
- Scripts: `Verb-Noun.ps1` in PascalCase (e.g. `Get-DiskInventory.ps1`)
- Variables: PascalCase or camelCase, meaningful names; no Hungarian prefixes
- Constants: `SCREAMING_SNAKE` via `$env:` or a config hashtable

## Structure

- `#requires -Version 7.0` at the top of newer scripts when 7+ features are used
- Parametrize with `[CmdletBinding()]` + `param()` blocks - never bake in machine-specific paths
- One concern per script; shared logic goes into dot-sourced `.ps1` files or modules (`.psm1`)
- Add comment-based help (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`) to scripts meant for reuse

## Formatting

- 4-space indentation
- Full cmdlet names - no aliases in committed scripts (`Get-ChildItem`, not `gci`)
- Splatting for commands with 4+ parameters
- Pipeline over loops when it reads clearly; explicit `foreach` when the logic is complex

## Output

- Return objects, not formatted strings (no `Format-Table` at the end of a script unless it's a report)
- `Write-Verbose` / `Write-Debug` for diagnostics, `Write-Warning` for warnings - never `Write-Host` inside reusable functions
