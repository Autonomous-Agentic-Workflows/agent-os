# Git Standards

## Commit Messages

- Conventional Commits format: `type(scope): description`
- Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build
- Description in lowercase imperative, no trailing period
- Body wraps at 72 chars; explains *why*, not *what*

## Per-Account Identity (multi-account wiring)

- `conor-ops` - active account (personal / work)
- `Autonomous-Agentic-Workflows` - shared org
- Others as configured; check `gh auth status` for the currently active identity

Set identity per-repo with `git config user.name` / `git config user.email`.
A global identity is currently configured for the active account; override it
per-repo whenever a repository belongs to a different account. Do not record
account emails in this standard.

## Workflow

- Branch from main with a descriptive short-name branch (no raw issue IDs unless needed)
- Use `git pull --rebase` before pushing; never merge main into a feature branch to "sync"
- Squash on merge to keep main linear
- Never force-push to shared branches (main, develop)

## Security

- Never commit secrets, tokens, .env, wallets, or recovery keys
- `.gitignore` must cover: .env, *.pem, *.p12, keys_and_wallets/, recovery.json (local), *.vhdx, *.vhd
- Use gitleaks (config at .gitleaks.toml in MasterRecovery3) for pre-commit checks where available
