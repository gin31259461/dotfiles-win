# README Patterns

## Recommended Default

Use this order when the project has enough evidence for each section:

1. Title
2. One-sentence purpose
3. Features
4. Requirements
5. Installation
6. Quick start
7. Usage
8. Configuration
9. Development
10. Testing
11. Project structure
12. Troubleshooting
13. License

Remove sections that do not add value

## CLI Tool

Prioritize:

- What the command does
- Installation
- Basic usage
- Common options
- Examples
- Configuration
- Exit behavior or safety notes when relevant

Include command examples early

## Library

Prioritize:

- Install command
- Minimal code example
- Core API concepts
- Supported runtimes or compatibility
- Links to detailed API docs when present

Avoid documenting private internals as public API

## Web App Or Service

Prioritize:

- Requirements
- Environment variables
- Local setup
- Run commands
- Test commands
- Deployment notes when present
- Architecture only when it helps contributors operate the app

Never invent hosted URLs or deployment targets

## Dotfiles

Prioritize:

- Target platform and shell or desktop assumptions
- Bootstrap or install commands
- Managed paths
- Package groups
- Maintenance commands
- Safety and backup notes

Keep personal details out unless they are already part of the repository purpose

## Plugin Or Codex Skill

Prioritize:

- What it enables
- When to use it
- Installation or location
- Invocation examples
- Files included
- Configuration

Keep instructions agent-facing for skills and user-facing for plugins

## Audit Report

Use this structure:

- Findings
- Missing or unclear information
- Suggested structure
- Optional rewrite notes

For code-review style audits, lead with concrete issues and file references
