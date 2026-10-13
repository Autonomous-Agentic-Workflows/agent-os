# GenAIMindMapFlowBuilder (`genai-mindmap`)

Modular FastAPI backend for AI-powered mind mapping with Neurite integration; routers for flows, qa, ingestion, sql and nodes. React+Vite frontend.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/GenAIMindMapFlowBuilder`
- **Path**: `D:\StudioProjects\GenAIMindMapFlowBuilder`
- **Kind**: service (python)
- **Status**: `needs-setup`
- **CLI**: `mindmap`

## Interfaces

```json
{
  "http": {
    "url": "http://localhost:8000",
    "run": "uvicorn backend.app:app --reload",
    "swagger": "http://localhost:8000/docs"
  },
  "frontend": {
    "path": "frontend",
    "run": "npm install && npm run dev"
  }
}
```

## Setup (if `status: needs-setup`)

- `python -m pip install -r backend/requirements_minimal.txt`

## Notes

Already agent-wired: GitHub-native Claude dispatch (.github/workflows/claude.yml), repository_dispatch 'claude-task', and a self-hosted 'genai-ollama-runner'.

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "genai-mindmap" })     # full entry
fleet_health({ id: "genai-mindmap" })   # probe path + ports
fleet_invoke({ id: "genai-mindmap" })   # run the declared command
```

Or from any shell (shim on PATH): `mindmap --help`
