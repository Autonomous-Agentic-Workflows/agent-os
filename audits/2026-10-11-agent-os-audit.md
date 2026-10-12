# Agent OS fleet audit — 2026-10-11

Read-only audit run by an opencode subagent fleet (5+ parallel workers) on `guyn-pc\jayla`.
Scope: `P:\agent-os` (repo), `L:\claude-config`, `C:\Users\jayla\.claude`, 5 project installs under
`D:\StudioProjects\`, legacy `S:\projects\agent-os`, `P:\RecoveryConsolidated`.
No files were modified. Secrets are redacted with `[SECRET]`.

Related: `inherited-context.md`, `agents-inventory.md` (in `C:\Users\jayla\.config\opencode\inherited\`).

---

## TL;DR

- Command + standards **content** is in perfect parity across all 8 locations, BUT the canonical source is uncommitted.
- The declared `recovery` profile is **broken** (no `profiles/recovery/` dir).
- `index.yml` is placeholder-only plus one malformed stray entry.
- 🔴 **A live-looking GitHub PAT and multiple sensitive recovery artifacts are committed** in two mirrored org repos.
- This Windows box **cannot run the Agent OS bash installer** (bash/WSL denied); Python is a stub; gcloud/sqlite3 missing.

---

## 1. Command parity (SHA256)

Commands: `discover-standards.md`, `index-standards.md`, `inject-standards.md`, `plan-product.md`, `shape-spec.md`.

| Location | Result |
|---|---|
| `P:\agent-os\commands\agent-os` (repo, baseline) | — |
| `L:\claude-config\commands\agent-os` | identical (all 5) |
| `C:\Users\jayla\.claude\commands\agent-os` | identical |
| MR3 / local-recovery / hermes / fictional-invention / MRA `\.claude\commands\agent-os` | identical (all 5) |

**Zero drift.** But distribution is copy-based with no sync script — parity is incidental, not enforced.

## 2. Standards parity

Repo `profiles/default/standards/` vs each project `agent-os/standards/` — **all byte-identical** for
`git/workflow.md`, `powershell/safety.md`, `powershell/style.md`, `python/code.md`, `recovery/policy.md`.

- **Repo has NO `index.yml`**; the whole `profiles/default/standards/` tree is **untracked** (`??`).
- All 5 projects: `agent-os/` untracked, `.claude/commands/agent-os/` untracked.
  - `local-recovery` has 263 dirty entries and `.claude/` is gitignored (its commands will never be tracked).
- Legacy `S:\projects\agent-os\standards\` is partial; its `index.yml` differs (has real descriptions).

## 3. `index.yml` audit

1. All 5 project copies identical; all 5 standard entries are placeholder: `Needs description - run /index-standards`.
2. Stray/malformed top-level entry `workflow:` ("Unification of MR2-MR3-MR4-MRA orchestration") — no such directory; invalid format.
3. `plan-product.md` expects `agent-os/standards/global/tech-stack.md`, but `project-install.sh` only copies `profiles/<profile>/standards/**`,
   so `global/` is never installed → tech-stack is orphaned.

## 4. `recovery` profile is broken

`config.yml` declares `recovery: inherits_from: default`, but `P:\agent-os\profiles\recovery\` does not exist.
`project-install.sh --profile recovery` fails immediately (`Profile not found: recovery`).
Root cause: recovery content sits inside `default` at `profiles/default/standards/recovery/policy.md`.

## 5. Stale To Go / old-topology references

Current reality: host `GUYN-PC`, user `jayla`, data `D:`, config `L:`, `gh` active `conor-ops`. No DESKTOP-7F4FEDJ/HP15/Homebook.

| File | Stale content | Should be |
|---|---|---|
| `standards/recovery/policy.md` | topology "DESKTOP-7F4FEDJ primary, HP15 worker, Homebook offline" | single machine `GUYN-PC` |
| `standards/recovery/policy.md` | "never hardcode `C:\Users\conor`" | username is `jayla` |
| `standards/powershell/safety.md` | "(`S:\`, `P:\` are data volumes)" | data volume `D:`; `S:` legacy |
| `standards/git/workflow.md` | accounts + embedded emails; "never global identity" | global identity IS set (`conor-ops`) → contradicts |
| `global/tech-stack.md` | Python "Documents\DevKit\py313" (no abs path) | only works via full path |

## 6. 🔴 Security — committed secrets (values redacted)

### CRITICAL
- **Live-looking GitHub PAT** tracked in `MasterRecovery3/config/mcp_config.json` (line 24): `ghp_VW…[SECRET]` (40 chars).
  `gh auth status` shows active `conor-ops` uses a `ghp_` token → treat as real. **Rotate/revoke now.**
  (MRA's copy is clean.)

### HIGH — sensitive artifacts tracked in MR3 (duplicated in MRA)
- `keys_and_wallets/`: `RECOVERY_TARGETS.txt`, `tokens.txt`, `decrypted_output*`.
- 7 × `data/temp_extract/*/credentials.csv`.
- Seed/key artifacts: `docs/SEED_F_VALIDATION_*`, `logs/SEEDB_SUCCESS_EXTENDED.txt`, `lib/crypto/seed_utils.py`,
  `lib/seed_manager.py`, `extract_all_23_seeds.py`, `validate_forensic_seeds.py`, `G_Drive_Imports/conor_208fenceandgate/*`.
- `autonomous-recovery/data/wallet-snapshots/*.json` (AKIA-pattern + `0x[64-hex]`).
- WIF-shaped strings in `clawdbot/wordlists/btcrecover/.../test-wallets/*` and `data/temp_extract/.../bookmarks.html`.

### MEDIUM
- MR3 and MRA are near-identical duplicate trees → **same exposure in two org repos**.
- `local-recovery`, `fictional-invention`: clean. `hermes` hits are dummies in tests.
- Pre-commit hook present but **inactive** (`core.hooksPath` unset). CI `secret-scan.yml` scans PR added lines only,
  and skips `clawdbot/logs/claude_bash_history.txt`.
- `.gitignore` misses `keys_and_wallets/`, `config/mcp_config.json`, `data/temp_extract/`,
  `autonomous-recovery/data/wallet-snapshots/`, `G_Drive_Imports/`, `docs/SEED_*`, `logs/SEEDB_*`.

## 7. Environment readiness gaps

| Item | Status | Impact |
|---|---|---|
| `python`/`python3` on PATH | MS Store stub (fails) | breaks pytest/vertex_orchestrator |
| Real Python 3.13 | `C:\Users\jayla\Documents\DevKit\py313\python.exe` (3.13.16) | only via abs path |
| `gcloud` | missing | breaks Drive workflows |
| `sqlite3` | missing | cannot inspect state DBs |
| `bash`/WSL | Access denied | **Agent OS bash installer non-functional** |
| pwsh 7.6.5 / git 2.56 / gh 2.102 / node 24 / npm 11 / ollama / VS Code | present | OK |
| C: free | ~8.6 GB | tight |

Also: `common-functions.sh` has mojibake glyphs (encoding bug).

---

## Prioritized fixes

### P0 — today (security)
1. Revoke/rotate the `ghp_…` PAT; purge from git history (git-filter-repo/BFG).
2. Treat `keys_and_wallets/*`, `credentials.csv`, `G_Drive_Imports/*`, wallet snapshots, seed artifacts as **exposed**;
   untrack + purge history (same for the MRA duplicate).
3. Extend `.gitignore` (see list above).
4. Enable hook: `git config core.hooksPath .githooks`; add `.gitleaks.toml` to MRA; scan full history in CI.

### P1 — structure/correctness
5. Commit canonical source: `profiles/default/standards/**`, `config.yml`, `tech-stack.md`.
6. Fix `recovery` profile (create dir and move `recovery/policy.md`, or drop the block).
7. Add repo `index.yml`; replace placeholders; remove stray `workflow:` entry.
8. Make `global/tech-stack.md` deliverable (install `global/` into projects).

### P2 — hygiene
9. Refresh stale To Go text (see §5).
10. Re-implement the 3 bash scripts in PowerShell (pwsh-first; bash unusable here).
11. Put `DevKit\py313` on PATH / disable Store alias; install gcloud + sqlite3; fix script encoding.
12. Archive legacy `S:\projects\agent-os` and `P:\RecoveryConsolidated` corrupted copies; reconcile memory note.
