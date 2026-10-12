# Python Standards

## Environment

- Python 3.13 at `C:\Users\jayla\Documents\DevKit\py313\python.exe` is the primary runtime (pip + pytest + pydantic)
- Python 3.14 exists at `C:\Users\jayla\Documents\DevKit\python` but has no pip - use 3.13
- Prefer a venv per project; never install into the global Python unless explicitly needed

## Code Style

- Type hints using PEP 604 (`int | None`) style - no `Optional[...]` from typing
- Use pydantic v2 for data validation and settings (not pydantic v1 patterns)
- Async where I/O-bound; use httpx, not requests, for new HTTP code
- f-strings for formatting, no `.format()` or `%` interpolation

## Testing

- Use pytest (not unittest) - test files named `test_*.py`
- Tests live in a `tests/` directory matching the package structure
- Use in-memory fakes / lambda doubles, not monkey-patching
- Target >= 85 percent coverage on core logic

## Project Layout

- Packages inside a `src/` layout (`src/package_name/`)
- Tests in `tests/` parallel to `src/`
- `pyproject.toml` is the source of truth for dependencies
- Never commit `.venv`, `__pycache__`, or `*.egg-info`

## Sensitive Data

- Never hardcode seeds, passphrases, WIF keys, API keys, or tokens in source
- Sensitive values read from environment or config files that are gitignored
- When logging sensitive material, redact via a sanitization helper before output
