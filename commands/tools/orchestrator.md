# vertex_orchestrator (`orchestrator`)

Unified REST API that routes tasks to CrewAI (analysis), AutoGen (conversation) and Aider (edit) via Google Vertex AI. Hosts the recovery-overseer child service.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/Orchestrator`
- **Path**: `D:\StudioProjects\Orchestrator`
- **Kind**: service (python)
- **Status**: `needs-setup`
- **CLI**: `orchestrator`

## Interfaces

```json
{
  "http": {
    "url": "http://localhost:8000",
    "run": "PYTHONPATH=src python -m vertex_orchestrator.server"
  },
  "python_api": {
    "import": "vertex_orchestrator",
    "entry": "Orchestrator(config).execute(task_type, task)"
  },
  "child_service": {
    "id": "recovery-overseer",
    "port": 3000
  }
}
```

## Setup (if `status: needs-setup`)

- `python -m pip install -e . (from repo root)`
- `requires Google Cloud / Vertex AI credentials`

## Secrets required

- Google Cloud / Vertex AI service account
- Google Workspace OAuth (via recovery-overseer)

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "orchestrator" })     # full entry
fleet_health({ id: "orchestrator" })   # probe path + ports
fleet_invoke({ id: "orchestrator" })   # run the declared command
```

Or from any shell (shim on PATH): `orchestrator --help`
