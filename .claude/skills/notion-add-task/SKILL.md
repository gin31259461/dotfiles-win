---
name: notion-add-task
description: Parses free-form text (or documents with links) and creates one or more tasks in the Notion Tasks database. Use when the user provides a task description, a URL to read, or a document and wants it added to their task list.
---

# Notion Add Task

Resolves user input into one or more structured task entries and writes them to the Notion `Tasks database` via `MCP`

## When to Use

- User pastes a task description, list of tasks, or a document
- User provides a URL and wants a task created from its content
- User says "add to tasks", "add this to my Notion", "create a task for…"

## When Not to Use

- User only wants to read or query existing tasks (use `notion_notion-search` instead)
- User wants to update or complete an existing task (use `notion_notion-update-page`)

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| Raw text / document | Yes | Free-form description, bullet list, or pasted document |
| URL(s) embedded in text | No | Will be fetched and summarized; summary is added to task Description |
| Due date hint | No | Natural-language date extracted from input (e.g. "by Friday", "2026-06-10 9am") |
| Priority hint | No | Natural-language priority extracted from input (e.g. "urgent", "low priority") |

## Timezone Rules

- **Workspace timezone**: GMT+8 (Asia/Taipei)
- When setting a datetime (time included): **always** append `+08:00` to the ISO string.
  - Correct: `"2026-06-05T09:00:00+08:00"`
  - Wrong: `"2026-06-05T09:00:00"` (Notion treats bare times as UTC → displays 8 h ahead)
- Date-only values (no time): no offset needed.
  - Correct: `"2026-06-05"`

## Workflow

### Step 1: Parse the input

Read the raw input carefully:

- Extract one or more distinct tasks. A numbered list or bullet list = multiple tasks.
- For each task identify: name, description hints, due date, time, priority, recurring pattern.
- Note any URLs present in the text.

### Step 2: Fetch URLs (if any)

For each URL found in the input:

- Use the `WebFetch` tool to retrieve the page content.
- Summarize the relevant content in 1–3 sentences.
- If fetch fails, note the URL and continue.

### Step 3: Resolve dates

Today's date is always available in the environment (`Today's date` in `<env>`).

- Interpret relative dates ("tomorrow", "next Monday", "end of week") against today in **GMT+8**.
- If a specific time is given, set `date:Due:is_datetime` = `1` and include `+08:00`.
- If no time is given, set `date:Due:is_datetime` = `0` and use a bare date.
- If no due date is mentioned, omit `Due` properties entirely.

### Step 4: Map priority

| Input hint | Notion value |
|---|---|
| urgent / critical / asap / high | `"High"` |
| medium / normal / default | `"Medium"` |
| low / someday / eventually | `"Low"` |
| no hint | omit Priority (leave unset) |

Also set `Smart List` = `"Someday"` when the user uses language like "someday", "eventually", or "when I have time".

### Step 4a: Map other properties

Decide other properties based on input you resolved, e.g. `relations`

### Step 5: Create task(s)

Use `notion_notion-create-pages`.

Create all tasks in a **single API call** (batch up to 100 pages).

Minimum required property: `Name`.
Always set `Status` = `"To Do"` unless the user says it's already in progress or done.

### Step 5a: Write content

Use `notion_notion-update-page` with `insert_content` to add task details to the page content.

If the task has clearly defined items that need to be completed, use Notion Markdown checkboxes (`- [ ]` / `- [x]`) in the content.

### Step 6: Confirm

After the API call succeeds, reply to the user with:

- A brief summary of what was created (task name, due date if set, priority if set).
- The Notion page URL(s) returned.

## Validation

- [ ] Each task has a `Name`
- [ ] Datetime values include `+08:00` offset; date-only values do not
- [ ] URL fetch attempted for every link in input
- [ ] Single `create-pages` call used (not one call per task)

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Bare datetime string (no offset) | Always append `+08:00` when a time is present |
| Writing to formula properties | Only write to properties listed in the "Writable properties" table above |
| Forgetting to fetch URLs | Always call WebFetch for every URL found in the input |
| Creating tasks one by one | Batch all tasks into one `create-pages` call |
| Omitting `Status` | Default to `"To Do"` unless user says otherwise |
| Setting `Smart List` = "Someday" AND a specific due date | Usually contradictory — ask for clarification or omit Smart List |
