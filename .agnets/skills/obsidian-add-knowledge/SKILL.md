---
name: obsidian-add-knowledge
description: Adds new knowledge to the Obsidian vault. Accepts pasted text, a URL (auto-fetches content), or a file. Determines the correct target file based on content, checks the sibling misc.md for related entries to merge in, then creates or updates the note.
---

# Obsidian: Add New Knowledge

Processes new knowledge from any input source, places it in the right vault file,
and consolidates any related fragments from the nearest `misc.md`.

## When to Use

- User pastes raw text, notes, or commands they want saved
- User provides a URL to save as a reference
- User drops or references a file whose content should be added to the vault
- User says "add this to my notes", "save this", "note this down", etc.

## When Not to Use

- Reorganizing or refactoring existing notes (no new content involved)
- Updating properties, tags, or frontmatter only
- Deleting or archiving notes

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| Content source | Yes | Pasted text, a URL, or a file path |
| Target hint | No | User may suggest a topic, filename, or folder |

## Vault Layout Reference

```
Knowledge_Base/
  inbox/                  ← unprocessed dumps
  projects/               ← active projects
  areas/
    ncnu/
    personal/             ← do NOT modify unless explicitly told
  resources/
    coding/               ← python.md, docker.md, nvim.md, git/, c-sharp/, web/, lua/
    linux/                ← net.md, boot.md, bluetooth.md, usb.md, arch/, misc.md
    ml/
    tools/                ← ms-word.md, orbit-lua/
  archives/
```

Every directory may contain a `misc.md` used as a catch-all for snippets that
haven't found a permanent home yet.

## Workflow

### Step 1: Resolve the input

- **URL** — call `WebFetch` to retrieve the page content before proceeding.
- **File path** — call `Read` to load the file content.
- **Pasted text** — use directly.

### Step 2: Determine the target file

Analyze the resolved content and identify:

1. **Topic domain** — which top-level folder fits best:
   - `resources/coding/` — programming languages, tools, frameworks, editors
   - `resources/linux/` — OS-level topics: networking, boot, hardware, distro config
   - `resources/ml/` — machine learning, AI, datasets
   - `resources/tools/` — standalone applications (not coding-specific)
   - `areas/ncnu/` — university coursework and research
   - `projects/<name>/` — if tied to an active project
   - `inbox/` — when topic is ambiguous or user hasn't indicated placement

2. **Specific file** — pick the most specific existing file for the topic:
   - e.g., git commands → `resources/coding/git/`
   - e.g., NetworkManager → `resources/linux/net.md`
   - e.g., Docker compose tips → `resources/coding/docker.md`

3. **New file** — if no existing file fits, determine a new path:
   - Filename: lowercase with hyphens for English topics (`ssh-tunneling.md`)
   - Chinese topics: Chinese characters are fine
   - Place inside the appropriate subfolder

Call `Read` on the target file if it exists to understand current structure before editing.

### Step 3: Check the sibling misc.md

After identifying the target directory, check whether `misc.md` exists there:

```
<target_directory>/misc.md
```

- Call `Read` on it if it exists.
- Scan every `##` section heading and its content.
- Identify any sections **clearly related** to the new knowledge's topic.
- If related sections are found, plan to:
  1. Merge those sections into the target file (Step 4).
  2. Remove those sections from `misc.md` (Step 5).

Only migrate a section when the match is clear and unambiguous. When in doubt, leave it in `misc.md`.

### Step 4: Write the content to the target file

**Format rules (from AGENTS.md):**
- Use `##` for top-level sections; no `#` title heading unless the file already has one.
- Fenced code blocks with language tags.
- Bold for UI labels / key terms; `==highlight==` for critical values.
- Markdown tables for reference data (shortcuts, commands, flags).
- No introductory or concluding prose — start directly with content.
- No comments explaining what was added.
- Match the language already used in the file (Chinese or English).

**Frontmatter:**
- Only add YAML frontmatter if the file already has it.
- If creating a new file and sibling files in the same directory use frontmatter, add it:
  ```yaml
  ---
  id: <filename-without-extension>
  aliases: []
  tags: []
  created: <YYYY-MM-DD HH:MM:SS>
  modified: <YYYY-MM-DD HH:MM:SS>
  ---
  ```

**Placement when updating an existing file:**
- Append new `##` sections at the end of the file.
- If the content clearly belongs inside an existing section (e.g., a new subsection), insert it there instead.
- Preserve all existing content exactly.

**Placement when creating a new file:**
- Write the content directly; do not add a `#` title heading.
- Do add frontmatter if siblings use it.

Call `Edit` or `Write` to apply the changes.

### Step 5: Remove migrated sections from misc.md

If sections were extracted from `misc.md` in Step 3:

- Call `Edit` to delete only the migrated `##` sections and their content from `misc.md`.
- Leave all other sections intact.
- If `misc.md` becomes empty after removal (only frontmatter remains), leave it as-is — do not delete the file.

### Step 6: Confirm to the user

Report briefly:
- Where the content was saved (relative vault path).
- Which sections (if any) were migrated from `misc.md`.
- If a new file was created.

## Validation

- [ ] Content is saved to a file in the correct vault folder
- [ ] Note format matches vault conventions (no `#` heading, `##` sections, correct code fences)
- [ ] Frontmatter added only if siblings use it
- [ ] Migrated misc.md sections are removed from misc.md and present in the target file
- [ ] No existing content was altered or removed unintentionally
- [ ] Language matches the file (Chinese/English)

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Creating `#` title heading in a new file | Use `##` sections only unless file already has `#` |
| Adding frontmatter when siblings don't use it | Check a sibling file first with `Read` |
| Migrating loosely related misc.md sections | Only migrate when topic match is clear and unambiguous |
| Modifying `areas/personal/` | Never touch this folder unless explicitly instructed |
| Placing content in `inbox/` when a better location is obvious | Only use inbox when genuinely ambiguous |
| Forgetting to remove migrated sections from misc.md | Always clean up misc.md after merging |
| URL input used as plain text without fetching | Always call `WebFetch` first for URL inputs |
