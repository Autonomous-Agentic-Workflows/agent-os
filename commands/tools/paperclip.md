# paperclip-autonomous-agents (`paperclip`)

Paperclip ('paperclipai') - app + CLI to orchestrate AI agent teams, with pluggable adapters (claude-local, codex-local, cursor-cloud/local, gemini-local, grok-local, opencode-local, pi-local, openclaw-gateway).

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/paperclip-autonomous-agents`
- **Path**: `D:\StudioProjects\paperclip-autonomous-agents`
- **Kind**: cli (node)
- **Status**: `blocked`
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

- `Blocked (incomplete fork): cli/esbuild.config.mjs imports scripts/cli-bundled-npm-dependencies.mjs (MISSING), and bundles workspace paths packages/shared + @paperclipai/server (both MISSING). Root package.json also lacks a 'workspaces' field, while cli/package.json uses 'workspace:*' deps. Restore the missing paths from upstream before building.`

## Notes

Repo also ships agent skills under .agents/skills (garden-inbox, paperclip-page, pr-gardening) and .claude/skills/design-guide + packages\adapters\hermes\skills\paperclip-task-bridge (both synced to agent-os\skills).

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "paperclip" })     # full entry
fleet_health({ id: "paperclip" })   # probe path + ports
fleet_invoke({ id: "paperclip" })   # run the declared command
```

Or from any shell (shim on PATH): `paperclipai --help`
