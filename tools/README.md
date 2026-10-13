# Agent OS - Fleet Tools

Cross-configuration layer that makes external repos usable as **tools** by the
agent fleet. One source of truth (`registry.json`) feeds four registration
surfaces:

| Surface | Location | Purpose |
|---|---|---|
| **MCP server** | `tools/mcp/fleet-tools/server.js` | Exposes every registered repo as callable MCP tools (zero npm deps). |
| **Skills** | repo `.claude/skills`, `.agents/skills` | Reusable skills shipped by the repos (e.g. `frontend-design`). |
| **CLI** | `C:\Users\jayla\AppData\Roaming\npm\*.cmd` | PATH shims so agents can run each tool from any shell. |
| **Fleet registry** | `MasterRecovery3`/`MasterRecoveryAgents` `config/agents.json` `tools` block | Lets the recovery fleet discover/delegate to the tools. |

## Registry

`registry.json` is canonical. Each entry records: `id`, `repo`, `path`, `kind`,
`status`, `summary`, `interfaces`, `setup`, `invoke_cli`, `skills`, `secrets`.

Current tools (cloned to `D:\StudioProjects`):

| id | kind | interface | status |
|---|---|---|---|
| `orchestrator` | service (py) | REST `:8000` + CrewAI/AutoGen/Aider | needs-setup |
| `recovery-overseer` | mcp-server (node) | MCP JSON-RPC `:3000/mcp` | needs-setup |
| `genai-mindmap` | service (py) | FastAPI `:8000/docs` | needs-setup |
| `agent-lightning` | cli+lib (py) | `agl` | needs-setup |
| `paperclip` | cli (node) | `paperclipai` | needs-setup |
| `memory-palace` | web-app (node) | `next dev` `:3000` | needs-setup |
| `gcm` | system-tool (.NET) | git credential helper | needs-setup |

> `status: needs-setup` means the repo is cloned and wired, but its runtime
> dependencies have not been installed yet. Run the `setup` steps in the entry.

## MCP: fleet-tools

A dependency-free stdio MCP server. Register in `~/.config/opencode/opencode.jsonc`:

```jsonc
"fleet-tools": {
  "type": "local",
  "command": ["node", "P:\\agent-os\\tools\\mcp\\fleet-tools\\server.js"],
  "enabled": true
}
```

Tools it exposes:

- `fleet_list` - list registered tools.
- `fleet_info` - details for one tool id.
- `fleet_health` - probe HTTP ports / paths and report up/down.
- `fleet_invoke` - run a tool's declared command (whitelisted; no arbitrary shell).

## Recovery-overseer MCP (native)

`recovery-overseer` already speaks MCP over HTTP. Register as a *remote* server
(disabled until the service is running):

```jsonc
"recovery-overseer": {
  "type": "remote",
  "url": "http://localhost:3000/mcp",
  "enabled": false
}
```

## CLI shims

Thin `.cmd` launchers live in the npm global bin (already on PATH). Each prints
setup instructions if the underlying tool is not installed yet.

- `fleet` - facade: `fleet list | info <id> | health | invoke <id>` and `fleet mcp`.
- `paperclipai`, `agl`, `orchestrator`, `mindmap`, `memory-palace`.

## Maintenance

Adding a tool = add one `registry.json` entry, then re-run
`P:\agent-os\tools\install-shims.ps1` (regenerates CLI shims). The MCP server and
commands read the registry live.
