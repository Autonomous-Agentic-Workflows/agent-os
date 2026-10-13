# recovery-overseer (`recovery-overseer`)

Node/Express dashboard that also exposes a Model Context Protocol (JSON-RPC 2.0) server plus Google Workspace tools (Gmail, Slides, Tasks, Keep, Drive) and a Spark/Gemini analytics engine.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/Orchestrator`
- **Path**: `D:\StudioProjects\Orchestrator\recovery_overseer`
- **Kind**: mcp-server (node)
- **Status**: `needs-setup`
- **CLI**: `-`

## Interfaces

```json
{
  "mcp_http": {
    "url": "http://localhost:3000/mcp",
    "proxy": "http://localhost:8000/overseer/mcp",
    "info": "http://localhost:8000/overseer/mcp/info"
  },
  "http": {
    "dev": "npm run dev",
    "build": "npm run build",
    "start": "node dist/server.cjs",
    "port": 3000
  }
}
```

## Setup (if `status: needs-setup`)

- `cd recovery_overseer && npm install`
- `requires Google Workspace OAuth + Cloud SQL/Firebase env`

## Secrets required

- GOOGLE_* OAuth
- Cloud SQL / Firebase credentials
- GEMINI_API_KEY

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "recovery-overseer" })     # full entry
fleet_health({ id: "recovery-overseer" })   # probe path + ports
fleet_invoke({ id: "recovery-overseer" })   # run the declared command
```
