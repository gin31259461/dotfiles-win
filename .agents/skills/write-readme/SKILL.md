---
name: write-readme
description: Create, improve, and audit README files for any project type. Use when Codex is asked to write a README, improve an existing README, review README quality, document a repository, create project documentation, make setup or usage instructions clearer, update a GitHub project page, or work with README.md or README-like files. Supports direct editing when explicitly requested, and otherwise asks whether to return content or modify files
---

# Write README

## Core Workflow

1. Classify the request as create, improve, or audit
2. Apply the editing policy before changing files
3. Inspect the repository unless the user only wants copy from provided text
4. Draft concise, factual content grounded in the repository
5. Preserve existing useful structure, terminology, and project voice
6. Verify commands, paths, package names, and claims before presenting them

## Editing Policy

Ask whether to edit files directly or return draft content when the user has not made the expected output clear

Edit files without asking when the prompt includes direct-edit intent such as:

- `no ask`
- `edit README directly`
- `update the README`
- `apply changes`
- `write it to README.md`

For audits, default to findings and recommendations unless the user asks for an applied rewrite

## Repository Inspection

Use repository evidence before writing project-specific instructions. Start with:

- Existing `README*`, `docs/`, `AGENTS.md`, `CONTRIBUTING*`, `LICENSE*`
- Manifests such as `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`, `Makefile`
- Entrypoints, CLIs, scripts, examples, tests, CI, Docker files, config files, and screenshots

Do not invent unsupported features, install steps, badges, metrics, compatibility claims, screenshots, or roadmap items

## README Defaults

Use a concise structure that fits the project. Prefer these sections when relevant:

- Project name and one-sentence purpose
- Features or capabilities
- Requirements
- Installation
- Quick start
- Usage examples
- Configuration
- Development commands
- Testing
- Project structure or architecture
- Troubleshooting
- License

Omit sections that would be empty, speculative, or not useful for the project

## Style

Write clear, fluent, easy-to-understand content

Keep content concise and task-focused

Avoid irrelevant icons, emoji, decorative badges, and novelty headings. Do not use a brain icon unless the project itself makes that clearly relevant

Avoid sentence-final periods in bullet and numbered list items unless needed for clarity. Keep punctuation that belongs to commands, file names, URLs, package names, versions, or multiple-sentence items

Use code fences for commands and examples. Prefer copyable command blocks over prose-heavy explanations

## Validation

use markdownlint-cli2

## Reference Files

Read [references/triggers.md](references/triggers.md) when refining when this skill should apply or interpreting explicit trigger phrases

Read [references/repo-inspection.md](references/repo-inspection.md) when deciding what files to inspect for a project type

Read [references/readme-patterns.md](references/readme-patterns.md) when choosing the README structure for a specific project type

Read [references/audit-checklist.md](references/audit-checklist.md) when auditing an existing README
