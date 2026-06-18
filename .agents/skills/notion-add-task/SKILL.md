---
name: notion-add-task
description: Create one or more Notion Tasks database entries from free-form text, URLs, or documents. Use when the user wants task descriptions parsed, dated, prioritized, and added to Notion.
---

# Notion Add Task

Turn user input into structured entries in the Notion `Tasks database`.

## Use When

- The user asks to add, create, or save tasks in Notion.
- The input is a task description, list, URL, or pasted document.
- The user provides due date, priority, checklist, or recurring-task hints.

## Do Not Use When

- The user only wants to search or read existing tasks.
- The user wants to update, complete, or delete an existing task.

## Timezone

- Workspace timezone: GMT+8, Asia/Taipei.
- Datetimes must include `+08:00`, for example
  `2026-06-05T09:00:00+08:00`.
- Date-only values use bare dates, for example `2026-06-05`.

## Workflow

1. Parse the raw input into distinct tasks. Lists usually mean multiple tasks.
2. For each task, extract name, description, due date, time, priority,
   checklist items, recurrence, and URLs.
3. Fetch every URL, summarize relevant content in one to three sentences, and
   add the summary to the task description. If fetch fails, include the URL and
   note the failure.
4. Resolve relative dates against today in GMT+8.
   - With a time: set `date:Due:is_datetime` to `1` and include `+08:00`.
   - Without a time: set `date:Due:is_datetime` to `0` and use a bare date.
   - Without a due date: omit `Due` properties.
5. Map priority hints:
   - `urgent`, `critical`, `asap`, `high`: `"High"`
   - `medium`, `normal`, `default`: `"Medium"`
   - `low`, `someday`, `eventually`: `"Low"`
   - no hint: leave Priority unset
6. Set `Smart List` to `"Someday"` only for open-ended language such as
   "someday" or "when I have time". Do not combine it with a specific due date
   unless the user clearly asks for both.
7. Create all tasks in one `notion_notion-create-pages` call. Batch up to 100
   pages. Set `Status` to `"To Do"` unless the user says otherwise.
8. Add page body details with `notion_notion-update-page` and
   `command = "insert_content"`. Use Markdown checklists when the task has
   concrete subitems.
9. Reply with each created task name, due date, priority, and Notion URL.

## Validate

- Every task has a `Name`.
- Datetimes include `+08:00`; date-only values do not.
- Every URL was fetched or recorded as failed.
- Tasks were batched in a single create call when possible.
- Only writable properties were set.
