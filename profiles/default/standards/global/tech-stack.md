# Tech Stack

## Primary

- PowerShell 7 (pwsh 7.x) at C:\Program Files\PowerShell\7\pwsh.exe - automation and tooling
- VS Code at C:\Program Files\Microsoft VS Code\ - editor and git integration
- Python 3.13 at C:\Users\jayla\Documents\DevKit\py313\python.exe (pip + pytest + pydantic preinstalled)
- Node 24 / npm 11 - installed via Program Files
- Git 2.56 (Program Files) + GitHub CLI (gh) for PRs, auth, and repo management

## Script Organization

- One script per task in dedicated folders
- Shared logic lives in dot-sourced .ps1 libraries or .psm1 modules
- Cross-repo shared helpers live in MasterRecovery3/lib/ or local-recovery/lib/

## Testing

- Pester 5+ for PowerShell scripts and functions
- pytest 9 for Python code (vertex_orchestrator uses 49 tests via DevKit Python 3.13)

## Version Control

- Git via GitHub CLI (gh) - auth, PRs, and review workflows use gh as primary
- Per-repo identity set via git config user.name / user.email, never global
- Multi-account support wired via git-integration-setup.py in fictional-invention

## Agents and Orchestration

- Claude Code + Codex CLI + Gemini CLI + OpenCode installed globally via npm
- Hermes agent runtime cloned at D:\StudioProjects\hermes-agent-recovery-skills
- Autonomous workflow coordinated via agent_messages/*.jsonl message bus
