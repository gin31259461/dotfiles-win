---
name: obsidian-add-knowledge
description: Create a structured Obsidian note from user text, a URL, or a local file. Use when the user wants useful knowledge extracted, classified into the vault, and saved as a note.
---

# Obsidian Add Knowledge

Create a concise knowledge note in the Obsidian vault from text, URLs, or local
files. Choose the PARA folder, follow local note conventions, and do not touch
blocked personal content.

## Use When

- The user asks to save, store, or add knowledge to notes.
- The input is a URL, article, reference, documentation, or pasted text.
- The user gives a local file path to ingest.

## Do Not Use When

- The user wants a Notion task. Use `notion-add-task`.
- The user asks only for a summary or answer.
- The user wants existing notes edited or reorganized.
- The target is personal diary content under `areas/personal/`.

## Inputs

- `content`: required text, URL, or local file path.
- `filename`: optional filename without `.md`; infer from the title if omitted.
- `folder`: optional PARA folder override, such as `resources/python/`.

## Workflow

1. Classify `content` as URL, existing local file, or plain text.
2. Extract source material.
   - URLs: fetch the page, summarize the relevant content, and keep the URL.
   - Files: read text files; for binary or image files, capture metadata only.
   - Plain text: use directly, or summarize first when very long.
3. Fetch and summarize any URLs embedded in the input. If fetch fails, note the
   failure and continue.
4. Pick the folder unless the user provided one:
   - Programming: `resources/programming/`
   - Linux or sysadmin: `resources/linux/`
   - Machine learning or data science: `resources/machine-learning/`
   - Job or career: `resources/job/`
   - University: `resources/university/`
   - Clearly project-specific material: `projects/`
   - General reference: `resources/`
5. Create `resources/<subfolder>/<filename>.md`, or the requested folder path.

## Note Format

Use the vault's sibling files as the final guide. Default to:

```markdown
## <Title>

<Concise practical notes using paragraphs, bullets, tables, or code blocks.>

## Source

<URL or file path, when available>
```

Rules:

- Use `##` as the top heading level.
- Use fenced code blocks with language tags.
- Use bold for UI labels and key names.
- Use `==highlight==` only for critical Obsidian highlights.
- Prefer Traditional Chinese when sibling files use it; otherwise use English.
- Do not add YAML frontmatter unless sibling files use it.
- Do not add introductory or closing filler.

## Validate

- The note exists at the intended path.
- Folder choice follows PARA and any user override.
- Formatting matches nearby notes and avoids `#` title headings.
- No files under `areas/personal/` were modified.
