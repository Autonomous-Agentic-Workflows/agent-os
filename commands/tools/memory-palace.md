# memory-palace-with-brain (`memory-palace`)

Next.js 14 'memory palace' knowledge app (Mongo/Mongoose, OpenAI, PostHog, Cloudinary). Ships two reusable agent skills.

## Basics

- **Repo**: `Autonomous-Agentic-Workflows/memory-palace-with-brain`
- **Path**: `D:\StudioProjects\memory-palace-with-brain`
- **Kind**: web-app (node)
- **Status**: `needs-setup`
- **CLI**: `memory-palace`

## Interfaces

```json
{
  "app": {
    "run": "npm run dev",
    "port": 3000,
    "build": "npm run build",
    "start": "npm start"
  }
}
```

## Setup (if `status: needs-setup`)

- `npm install`
- `copy .env.example -> .env.local and fill secrets`

## Skills shipped

- `frontend-design`
- `integration-nextjs-app-router`

## How agents use it

Via the **fleet-tools** MCP server:

```
fleet_info({ id: "memory-palace" })     # full entry
fleet_health({ id: "memory-palace" })   # probe path + ports
fleet_invoke({ id: "memory-palace" })   # run the declared command
```

Or from any shell (shim on PATH): `memory-palace --help`
