# Skills

Reusable agent skills synced from the fleet tools. Each folder contains a
`SKILL.md` (plus any `references/`, `scripts/`, assets) as shipped by its source
repo.

| Skill | Source tool | Source path |
|---|---|---|
| `frontend-design` | memory-palace | `.agents/skills/frontend-design` |
| `integration-nextjs-app-router` | memory-palace | `.claude/skills/integration-nextjs-app-router` |
| `design-guide` | paperclip | `.claude/skills/design-guide` |
| `paperclip-task-bridge` | paperclip | `packages/adapters/hermes/skills/paperclip-task-bridge` |

## Provenance & updates

These are **copies**, not symlinks, so the fleet can load them even when the
source repos are not checked out. To refresh after a source repo changes:

```powershell
P:\agent-os\tools\sync-skills.ps1
```

Canonical tool metadata lives in `../tools/registry.json` (each entry lists its
`skills`).
