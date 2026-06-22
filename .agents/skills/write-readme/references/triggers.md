# Trigger And Editing Policy

## Use This Skill For

- `write a README`
- `create a README`
- `generate README.md`
- `improve this README`
- `rewrite my README`
- `audit this README`
- `review README quality`
- `document this repo`
- `make the project page clearer`
- `add setup instructions`
- `add usage examples`
- `update installation docs`
- `fix README structure`
- `make README concise`
- Requests that mention `README.md`, `README`, repository documentation, or GitHub project pages

## Direct Edit Triggers

Edit files without asking when any of these are present:

- `no ask`
- `don't ask`
- `do not ask`
- `edit directly`
- `apply it`
- `apply changes`
- `write it to README.md`
- `update README.md`
- `modify the README`
- `commit-ready`

Also edit directly when the surrounding system or user instruction clearly says to implement the change rather than propose it

## Ask First Cases

Ask one concise question when the user has not made the output target clear:

- Whether to edit the file or return draft content
- Which README file to update when multiple likely README files exist
- Whether to replace or preserve a heavily customized existing README
- Whether to include sections that require missing facts, such as license, screenshots, deployment, pricing, or roadmap

Do not ask for information that can be discovered from the repository

## Output Modes

For create requests:

- Prefer creating `README.md` at the repository root if no README exists and direct editing is allowed
- Return complete Markdown content if direct editing is not allowed

For improve requests:

- Preserve accurate existing content
- Remove duplication, stale claims, and empty sections
- Keep project-specific terminology

For audit requests:

- Lead with findings ordered by severity
- Include file and line references when available
- Note missing verification or repository facts
