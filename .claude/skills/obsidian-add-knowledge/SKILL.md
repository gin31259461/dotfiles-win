---
name: obsidian-add-knowledge
description: Parses user-provided text, URL, or file path to extract useful knowledge and adds it as a properly structured note in the Obsidian vault. Automatically fetches and summarizes web content when a URL is given.
---

# Obsidian Add Knowledge

Extracts knowledge from free-form input (text, URLs, or file paths), determines the correct PARA folder, and creates a well-structured note following vault conventions.

## When to Use

- User provides a block of text and wants it saved as a knowledge note
- User provides a URL and wants key information extracted and stored
- User provides a file path (local) and wants contents ingested into the vault
- User says anything like "save this", "add this to my notes", "store this knowledge"
- User pastes an article, documentation snippet, or reference material

## When Not to Use

- User explicitly wants a task created in Notion (use notion-add-task instead)
- User wants existing notes edited or reorganized (edit directly)
- User asks for a summary or question about existing notes (answer directly)
- Input is personal/diary content under `areas/personal/` (blocked per AGENTS.md)

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| content | Yes | Free-form text, URL (must start with http:// or https://), or file path |
| filename | No | Desired filename (without extension); auto-generated from title if omitted |
| folder | No | Specific PARA subfolder override (e.g., `resources/python/`); auto-classified if omitted |

## Workflow

### Step 1: Classify the input type

Determine whether `content` is:

- **URL** — starts with `http://` or `https://`
- **File path** — matches an existing local file path
- **Plain text** — everything else

### Step 2: Extract source material

- **URL**: Use `webfetch` to download the page. Extract the title, a concise summary (2-4 paragraphs), and key bullet points. Note the source URL.
- **File path**: Read the file. If it is a binary or image, extract metadata only; if text, extract key content.
- **Plain text**: Use directly. If very long (>2000 chars), produce a concise summary first.

### Step 2a: Fetch URLs (if any)

For each URL found in the input:

- Use the `WebFetch` tool to retrieve the page content.
- Summarize the relevant content in 1–3 sentences.
- If fetch fails, note the URL and continue.

### Step 3: Classify the PARA folder

Determine the target folder based on content type and AGENTS.md vault rules:

| Content Type | Default Folder | Notes |
|--------------|----------------|-------|
| Programming topic / language / tool | `resources/programming/` | Subfolder by language/tool name |
| Linux / sysadmin topic | `resources/linux/` | |
| Machine learning / data science | `resources/machine-learning/` | |
| Job / career topic | `resources/job/` | |
| University / academic topic | `resources/university/` | Subfolder by course if inferable |
| General reference | `resources/` | |
| Active project material | `projects/` | Only if clearly project-specific |

If `folder` input is provided, use that instead.

### Step 4: Generate the note

Create the file at `resources/<subfolder>/<filename>.md`.

The note follows AGENTS.md conventions:

```markdown
## <Title derived from content>

<2-4 paragraphs of concise, practical notes — bullet points, code blocks, commands, tables.>

## Source

<URL or file path if applicable>
```

Formatting rules:

- Use `##` top-level headings (no `#` title)
- Use fenced code blocks with language tags
- Bold (**text**) for UI labels, key names
- Use `==highlight==` for critical values (Obsidian)
- Use Markdown tables for reference data
- Prefer Traditional Chinese if existing sibling files use it; English otherwise
- No blank line before any heading level
- No YAML frontmatter unless sibling files in the same directory use it

### Step 5: Validate

- [ ] File was created at the expected path
- [ ] Content follows AGENTS.md formatting conventions
- [ ] No frontmatter added unless sibling files use it
- [ ] No `#` title heading unless the target file already has one
- [ ] No introductory or concluding prose
- [ ] No modification to files under `areas/personal/`
- [ ] Existing files were not reformatted or reorganized

## Validation

- Confirm the note appears in the correct PARA folder
- Spot-check 2-3 formatting rules from AGENTS.md
- If a URL was provided, verify the fetched content is accurate

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| URL fetch fails or times out | Fall back to using the URL as a plain-text source; note the fetch failure |
| File path does not exist | Return an error message listing the absolute paths checked |
| Content is too long (>500 lines) | Extract a summary; optionally split into multiple notes with references |
| Language mismatch with existing files | Check sibling files in the target directory before choosing language |
| Auto-classified folder is wrong | Allow user to override with the `folder` input |
