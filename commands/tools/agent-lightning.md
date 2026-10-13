# agent-lightning (`agent-lightning`)

Microsoft framework for training/optimizing AI agents; ships the 'agl' CLI (store, vllm, prometheus, agentops) and example FastMCP retrievers.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/agent-lightning`
- **Path**: `D:\StudioProjects\agent-lightning`
- **Kind**: cli+library (python)
- **Status**: `needs-setup`
- **CLI**: `agl`

## Interfaces

```json
{
  "cli": {
    "bin": "agl",
    "subcommands": [
      "store",
      "vllm",
      "prometheus",
      "agentops"
    ]
  },
  "python_api": {
    "import": "agentlightning"
  },
  "example_mcp": {
    "path": "examples\\rag\\wiki_retriever_mcp.py",
    "framework": "fastmcp"
  }
}
```

## Setup (if `status: needs-setup`)

- `python -m pip install agentlightning  (or: pip install -e . from repo root)`

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "agent-lightning" })     # full entry
fleet_health({ id: "agent-lightning" })   # probe path + ports
fleet_invoke({ id: "agent-lightning" })   # run the declared command
```

Or from any shell (shim on PATH): `agl --help`
