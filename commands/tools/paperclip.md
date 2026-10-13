# paperclip-autonomous-agents (`paperclip`)

Paperclip ('paperclipai') - app + CLI to orchestrate AI agent teams, with pluggable adapters (claude-local, codex-local, cursor-cloud/local, gemini-local, grok-local, opencode-local, pi-local, openclaw-gateway).

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/paperclip-autonomous-agents`
- **Path**: `D:\StudioProjects\paperclip-autonomous-agents`
- **Kind**: cli (node)
- **Status**: `needs-setup`
- **CLI**: `paperclipai`

## Interfaces

```json
{
  "cli": {
    "bin": "paperclipai",
    "entry": "cli\\dist\\index.js",
    "dev": "npm run dev",
    "build": "npm run build"
  },
  "adapters": [
    "adapter-claude-local",
    "adapter-codex-local",
    "adapter-cursor-cloud",
    "adapter-cursor-local",
    "adapter-gemini-local",
    "adapter-grok-local",
    "adapter-opencode-local",
    "adapter-pi-local",
    "adapter-openclaw-gateway"
  ]
}
```

## Setup (if `status: needs-setup`)

- `cd cli && npm install && npm run build  (npm workspace; build needs the @paperclipai/* workspace packages)`

## Notes

Repo also ships agent skills under .agents/skills (design-guide, paperclip) and .github skills.

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "paperclip" })     # full entry
fleet_health({ id: "paperclip" })   # probe path + ports
fleet_invoke({ id: "paperclip" })   # run the declared command
```

Or from any shell (shim on PATH): `paperclipai --help`
