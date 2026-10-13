# Fleet Tools

External repos registered as tools for the agent fleet. Canonical source:
`agent-os/tools/registry.json`. One command file per tool:

| Command | id | kind | status |
|---|---|---|---|
| orchestrator | `orchestrator` | service | `ready` |
| recovery-overseer | `recovery-overseer` | mcp-server | `ready` |
| genai-mindmap | `genai-mindmap` | service | `ready` |
| agent-lightning | `agent-lightning` | cli+library | `ready` |
| paperclip | `paperclip` | cli | `blocked` |
| memory-palace | `memory-palace` | web-app | `ready` |
| gcm | `gcm` | system-tool | `needs-setup` |

## MCP access

The `fleet-tools` MCP server exposes `fleet_list`, `fleet_info`,
`fleet_health` and `fleet_invoke`. The `fleet` CLI mirrors it:

```
fleet list
fleet info <id>
fleet health [id]
fleet invoke <id> [command]
fleet mcp          # run the MCP server on stdio
```
