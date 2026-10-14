# paperclip-autonomous-agents (`paperclip`)

Paperclip ('paperclipai') - app + CLI to orchestrate AI agent teams, with pluggable adapters (claude-local, codex-local, cursor-cloud/local, gemini-local, grok-local, opencode-local, pi-local, openclaw-gateway).

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/paperclip-autonomous-agents`
- **Path**: `D:\StudioProjects\paperclip-autonomous-agents`
- **Kind**: cli (node)
- **Status**: `ready`
- **CLI**: `paperclipai`

## Interfaces

```json
{
  "cli": {
    "bin": "paperclipai",
    "entry": "cli\\dist\\index.js",
    "dev": "npm run dev",
    "build": "node build.mjs  (run in cli/; the repo's 'npm run build' appends 'chmod +x', which fails on Windows)"
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

- `DONE -> built and on PATH. Steps: (1) restore missing monorepo paths from upstream/master: scripts/cli-bundled-npm-dependencies.mjs, packages/shared, packages/db (its src/index.ts was absent), packages/plugins; (2) pnpm install --store-dir L:\pnpm-store (pnpm@9.15.4 monorepo); (3) add esbuild to root devDependencies; (4) add cli deps @paperclipai/shared + @paperclipai/hermes-paperclip-adapter (workspace:*) plus runtime externals zod, ws, three, postgres, @agentclientprotocol/claude-agent-acp, @agentclientprotocol/codex-acp, @embedded-postgres/windows-x64; (5) build with 'node build.mjs' in cli/ -> cli/dist/index.js (~2.9MB). Shim: C:\Users\jayla\AppData\Roaming\npm\paperclipai(.cmd) -> node cli/dist/index.js.`
- `NOTE: @paperclipai/server is intentionally external (published separately, dynamic import) and is not present in this fork; server-dependent commands (run/service) need it. Verified: 'paperclipai --version' -> 0.3.1 and the full --help command tree.`

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
