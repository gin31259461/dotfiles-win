---
name: notion-financer
description: Manage the Financer Notion workspace, log income and expenses, maintain recurring bills, query balances and spending, manage categories and accounts, and create monthly reports.
---

# Notion Financer

Work with the Financer Notion workspace and its five linked databases:
Transactions, Categories, Accounts, Fixed Expenses, and Monthly Report.

Do not hardcode database, data source, template, or page IDs. Run Pre-flight at
the start of each session and use discovered values.

## Use When

- Logging income or expenses.
- Adding or updating recurring fixed expenses.
- Querying spending, balances, categories, or monthly summaries.
- Adding finance categories or accounts.
- Migrating finance data.
- Creating or reviewing a monthly report.

## Do Not Use When

- The request is about generic Notion pages outside finance.
- The user wants database schemas changed.
- The user asks to read dashboard pages; fetch the page URL directly.

## Timezone

- Workspace timezone: GMT+8, Asia/Taipei.
- Datetimes include `+08:00`, for example
  `2026-06-05T09:00:00+08:00`.
- Date-only values use bare dates and `is_datetime = 0`.

## Workflow Index

- `workflows/preflight.md`: run first every session.
- `workflows/add-transaction.md`: income or expense.
- `workflows/add-fixed-expense.md`: recurring bills.
- `workflows/add-account.md`: new payment source.
- `workflows/query.md`: balances, breakdowns, and totals.
- `workflows/migration.md`: bulk import.
- `workflows/monthly-report.md`: end-of-period report.

Reference files:

- `reference/databases.md`: schemas and writable properties.
- `reference/categories-accounts.md`: starter categories and accounts.

## Rules

- `Amount` is always positive; formulas handle sign.
- Category and Account relations are JSON arrays of page URLs.
- Fixed Expenses has one entry per recurring item.
- `Total Months` is `null` or `-1` for indefinite fixed expenses.
- Monthly Report has one row per month; reuse existing rows.
- Never write to read-only formula, rollup, or back-relation properties.
- Scoped `notion_notion-search` can be incomplete. For database searches, use
  workspace search plus ancestor-path verification when scoped results are
  missing, empty, or typed as `workspace_search`.

## Validate

- Pre-flight ran and no hardcoded UUIDs were used.
- Relations are JSON arrays of page URLs.
- Amounts are positive.
- Datetime and date-only values follow timezone rules.
- Fixed expenses and monthly reports were deduplicated.
- Read-only properties were not written.
