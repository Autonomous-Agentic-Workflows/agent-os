# Recovery Operation Standards

## Guard Levels

- standard - normal engineering / docs / validation work
- sensitive - forensics, wallet-adjacent analysis; use sanitized identifiers only
- critical - irreversible financial movement, private key handling, live credential use

Never exceed the guard level for the current task. Escalate to the user before any
critical operation.

## Sanitization Rules

- Never copy raw seed words, passphrases, WIF keys, extended private keys, tokens,
  API keys, account IDs, emails, recovery keys, or full wallet / address identifiers
  into docs, logs, reports, commits, or agent messages.
- Use labels, fingerprints, masked prefixes, or source-file references instead.
- Sanitized values go through the sanitization helper in lib.crypto (MasterRecovery3),
  or the equivalent in the local-recovery repo.

## Filesystem Boundaries

- MasterRecovery3 lives at D:\StudioProjects\MasterRecovery3
- local-recovery lives at D:\StudioProjects\local-recovery
- hermes-agent-recovery-skills lives at D:\StudioProjects\hermes-agent-recovery-skills
- vertex_orchestrator lives at D:\StudioProjects\fictional-invention
- Recovery repo path is resolved by paths.recovery_repo() from ORCHESTRATOR_RECOVERY_REPO
  or by scanning development_bases - never hardcode C:\Users\jayla or C:\src paths

## Network / Machine Policy

- No irreversible operations (broadcast, sweep, spend) against live wallets without
  explicit user authorization for each transaction.
- Prefer dry-run and monitor paths before state-changing calls.
- This fleet is a single workstation (GUYN-PC, user jayla) - there are no remote worker
  nodes. Do not attempt reconnects or cross-machine operations the user did not request.
