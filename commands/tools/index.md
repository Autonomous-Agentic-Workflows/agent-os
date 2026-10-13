# Fleet Tools

External repos registered as tools for the agent fleet. Canonical source:
`agent-os/tools/registry.json`. One command file per tool:

| Command | id | kind | status |
|---|---|---|---|
| orchestrator | `orchestrator` | service | `needs-setup` |
| recovery-overseer | `recovery-overseer` | mcp-server | `needs-setup` |
| genai-mindmap | `genai-mindmap` | service | `needs-setup` |
| agent-lightning | `agent-lightning` | cli+library | `needs-setup` |
| paperclip | `paperclip` | cli | `needs-setup` |
| memory-palace | `memory-palace` | web-app | `needs-setup` |
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
