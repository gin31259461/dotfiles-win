# Repository Inspection

## Baseline Files

Inspect these first when present:

- `README*`
- `AGENTS.md`
- `docs/`
- `examples/`
- `LICENSE*`
- `CONTRIBUTING*`
- `CHANGELOG*`
- `.github/workflows/`
- `Dockerfile`, `docker-compose.yml`, `compose.yml`
- `Makefile`, `justfile`, `Taskfile.yml`

Use `rg --files` to list files. Use targeted reads after identifying the likely project type

## Project Type Signals

Node and frontend:

- `package.json`, lockfiles, `vite.config.*`, `next.config.*`, `src/`, `public/`
- Read scripts, dependencies, entrypoints, routes, and test commands

Python:

- `pyproject.toml`, `requirements*.txt`, `setup.py`, `uv.lock`, `poetry.lock`
- Read package metadata, console scripts, modules, tests, and examples

Rust:

- `Cargo.toml`, `src/main.rs`, `src/lib.rs`, examples, benches
- Read crate metadata, binaries, features, and test commands

Go:

- `go.mod`, `cmd/`, `internal/`, `pkg/`, examples
- Read module path, binaries, server entrypoints, and test commands

Shell and dotfiles:

- `.local/bin/`, `.config/`, `install*`, `bootstrap*`, `scripts/`, TOML/YAML configs
- Document commands, assumptions, supported environment, and safety notes

Plugin or skill:

- Manifest files, `SKILL.md`, `.codex-plugin/plugin.json`, examples, bundled resources
- Document purpose, trigger/use cases, structure, and install or invocation path

Libraries:

- Public API files, examples, generated docs, tests
- Prioritize install, minimal usage, API surface, compatibility, and versioning notes

Apps and services:

- Entrypoints, environment variables, database migrations, deployment files, tests
- Prioritize requirements, local setup, configuration, run commands, and operational notes

## Verification

Prefer commands already declared in manifests or task files

Run lightweight commands only when useful and safe, such as:

- `npm run`
- `python -m pytest --help`
- `cargo test --help`
- `go test ./...`
- `make help`

Avoid running install, migration, deployment, cleanup, or destructive commands unless the user asks

If a command is not verified, phrase it as inferred from the repository rather than guaranteed
