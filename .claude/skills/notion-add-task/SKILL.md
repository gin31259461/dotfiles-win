---
name: notion-add-task
description: Parses free-form text (or documents with links) and creates one or more tasks in the Notion Tasks database. Use when the user provides a task description, a URL to read, or a document and wants it added to their task list.
---

# Notion Add Task

Resolves user input into one or more structured task entries and writes them to the Notion Tasks database (`collection://bd7e5198-eb31-8382-9818-87e37c4ac2e1`).

## When to Use

- User pastes a task description, list of tasks, or a document
- User provides a URL and wants a task created from its content
- User says "add to tasks", "add this to my Notion", "create a task for…"

## When Not to Use

- User only wants to read or query existing tasks (use `query_data_sources` instead)
- User wants to update or complete an existing task (use `notion-update-page`)

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| Raw text / document | Yes | Free-form description, bullet list, or pasted document |
| URL(s) embedded in text | No | Will be fetched and summarized; summary is added to task Description |
| Due date hint | No | Natural-language date extracted from input (e.g. "by Friday", "2026-06-10 9am") |
| Priority hint | No | Natural-language priority extracted from input (e.g. "urgent", "low priority") |

## Database Reference

- **Data source ID**: `bd7e5198-eb31-8382-9818-87e37c4ac2e1`
- **Writable properties** (only set these; all others are formula/read-only):

| Property | Type | Values / Notes |
|----------|------|----------------|
| `Name` | title | Task name (required) |
| `Description` | text | Short plain-text summary |
| `Status` | status | `"To Do"` · `"Doing"` · `"Done"` — default `"To Do"` |
| `Priority` | status | `"Low"` · `"Medium"` · `"High"` |
| `date:Due:start` | ISO-8601 | Date or datetime. **Include `+08:00` offset when a time is present.** |
| `date:Due:end` | ISO-8601 | Optional range end. Must be NULL for single dates. |
| `date:Due:is_datetime` | int | `1` if time present, `0` if date-only |
| `Smart List` | select | `"Someday"` — omit unless explicitly a someday task |
| `Recur Interval` | number | Interval number for recurring tasks |
| `Recur Unit` | select | `"Day(s)"` · `"Week(s)"` · `"Month(s)"` · `"Month(s) on the First Weekday"` · `"Month(s) on the Last Weekday"` · `"Month(s) on the Last Day"` · `"Year(s)"` |
| `Days (Only if Set to 1 Day(s))` | multi_select | `["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]` — only when Recur Interval=1 and Recur Unit="Day(s)" |
| `Project` | relation | JSON string of a single Projects page URL |
| `Parent Task` | relation | JSON string of a single Tasks page URL (for sub-tasks) |

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
- Append the summary to the task's `Description` field (prepend the source URL).
- If fetch fails, note the URL in Description and continue.

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

### Step 5: Create task(s)

Use `notion_notion-create-pages` with:
```json
{
  "parent": { "data_source_id": "bd7e5198-eb31-8382-9818-87e37c4ac2e1" },
  "pages": [ { "properties": { ... } } ]
}
```

Create all tasks in a **single API call** (batch up to 100 pages).

Minimum required property: `Name`.
Always set `Status` = `"To Do"` unless the user says it's already in progress or done.

### Step 6: Confirm

After the API call succeeds, reply to the user with:
- A brief summary of what was created (task name, due date if set, priority if set).
- The Notion page URL(s) returned.

## Validation

- [ ] Each task has a `Name`
- [ ] Datetime values include `+08:00` offset; date-only values do not
- [ ] No formula/read-only columns are written (`Created`, `Edited`, `Next Due`, `Due Stamp (Parent)`, `Due Timestamp`, `Meta Labels`, `Localization Key`, `Sub-Task Arrow`, `Sub-Task Sorter`, `Recurring Tasks Divider`, `UTC Offset`, `Project Active`, `Parent Project`)
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
