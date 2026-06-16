---
name: notion-personal-finance
description: Manages the Financer Notion workspace — recording transactions, managing fixed expenses, querying spending summaries, and maintaining categories and accounts. Use when the user wants to log income or expenses, add/update recurring bills, check balances, or report on spending.
---

# Notion Financer

Provides a complete workflow for interacting with the Financer Notion workspace. Five linked databases — Transactions, Categories, Accounts, Fixed Expenses, Monthly Report.

**Critical**: Do NOT hardcode any IDs (data source, template, or page). Always discover them dynamically via the Pre-flight workflow.

## When to Use

- Log an income or expense transaction
- Add or update a recurring fixed expense (subscription, loan, tax)
- Query a spending summary, balance, or category breakdown
- Add a new category or account
- Migrate data from another finance source
- Create or review a monthly report

## When Not to Use

- Querying generic Notion pages unrelated to finance
- Modifying database *schemas* (add/remove properties)
- Reading Finance Dashboard pages — fetch the page URL directly

## Timezone Rules

- **Workspace timezone**: GMT+8 (Asia/Taipei)
- **Datetime values** (time included): append `+08:00`
  - Correct: `"2026-06-05T09:00:00+08:00"`
- **Date-only values**: bare ISO date, no offset, `is_datetime` = `0`
  - Correct: `"2026-06-05"`

## Workflow Index

| Workflow | File | When |
|---|---|---|
| Pre-flight (run first) | `workflows/preflight.md` | Every session before any other workflow |
| Add Transaction | `workflows/add-transaction.md` | Income or expense |
| Add Fixed Expense | `workflows/add-fixed-expense.md` | Recurring bills |
| Add Account | `workflows/add-account.md` | New payment source |
| Query / Summarize | `workflows/query.md` | Balances, breakdowns, totals |
| Batch Migration | `workflows/migration.md` | Bulk import |
| Create Monthly Report | `workflows/monthly-report.md` | End-of-period report |

**Always start by reading `workflows/preflight.md`** to discover database IDs and template. Results are stored as variables used by all other workflows.

## Reference Files

| File | Contents |
|---|---|
| `reference/databases.md` | All 5 database schemas with writable properties |
| `reference/categories-accounts.md` | Pre-populated categories and accounts |

## Cross-Cutting Rules

- `Amount` is always a positive number (sign handled by formula)
- Category/Account relations are JSON arrays of page URLs, not IDs or names
- Fixed Expenses has one entry per recurring item (not one per billing period)
- `Total Months` is `null` or `-1` for indefinite recurring expenses
- Monthly Report has one row per month; reuse existing row rather than duplicating
- Read-only formula/rollup properties must never be written to
- `notion_notion-search` with `data_source_url` scoped search is unreliable — always use the two-pass fallback (workspace search + ancestor-path verification). Applies to ALL database searches.

## Validation Checklist

- [ ] Ran Pre-flight — no hardcoded UUIDs
- [ ] Category/Account relations are JSON arrays of page URLs
- [ ] `Amount` always positive
- [ ] Datetime values include `+08:00`; date-only values do not
- [ ] Fixed Expenses have one entry per recurring item
- [ ] Monthly Report has one row per month; reused existing if found
- [ ] Read-only properties never written to
