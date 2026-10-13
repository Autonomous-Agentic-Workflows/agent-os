# git-credential-manager-8e947aa1 (`gcm`)

Fork of Git Credential Manager (GCM) - secure credential helper for Git. Usable as a tool to manage/store git credentials without embedding tokens.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/git-credential-manager-8e947aa1`
- **Path**: `D:\StudioProjects\git-credential-manager-8e947aa1`
- **Kind**: system-tool (dotnet)
- **Status**: `needs-setup`
- **CLI**: `-`

## Interfaces

```json
{
  "credential_helper": {
    "config": "git config --global credential.helper manager",
    "binary": "git-credential-manager"
  }
}
```

## Setup (if `status: needs-setup`)

- `dotnet build (requires .NET SDK)`
- `then: git config --global credential.helper manager`

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "gcm" })     # full entry
fleet_health({ id: "gcm" })   # probe path + ports
fleet_invoke({ id: "gcm" })   # run the declared command
```
