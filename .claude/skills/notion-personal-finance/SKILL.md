---
name: notion-personal-finance
description: Manages the Personal Finance Notion workspace — recording transactions, managing fixed expenses, querying spending summaries, and maintaining categories and accounts. Use when the user wants to log income or expenses, add/update recurring bills, check balances, or report on spending.
---

# Notion Personal Finance

Provides a complete workflow for interacting with the Personal Finance Notion workspace. The system consists of five linked databases. This skill covers every operation: inserting transactions, managing fixed expenses, maintaining reference data (categories, accounts), generating monthly reports, and summarizing finances.

## When to Use

- User wants to log an income or expense transaction
- User wants to add or update a recurring fixed expense (subscription, loan, tax)
- User asks for a spending summary, balance, or category breakdown
- User wants to add a new category or account
- User migrates data from another finance source
- User wants to create or review a monthly report

## When Not to Use

- Querying generic Notion pages unrelated to finance
- Modifying the database *schemas* (add/remove properties) — use `notion-update-data-source` directly
- Reading Finance Dashboard pages — fetch the page URL directly instead

## Database Reference

All five databases live under the **💰 Personal Finance** page.

| Database | Icon | Data Source ID | Purpose |
|---|---|---|---|
| Transactions DB | 💸 | `374e5198-eb31-80db-829c-000bc278fc83` | Every income and expense event |
| Categories DB | 🏷️ | `374e5198-eb31-80c8-a554-000ba26b86da` | Category definitions + monthly budgets |
| Accounts DB | 🏦 | `374e5198-eb31-8050-a7fa-000bf463ec46` | Bank/cash accounts + balances |
| Fixed Expenses DB | 📋 | `374e5198-eb31-80ed-8947-000b9e7a9884` | Recurring expense definitions |
| Monthly Report DB | 📊 | `aa21aa5c-c752-43df-9f62-fa7b9d8c9259` | Monthly reports aggregating income, expenses, and net |

### Transactions DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Item Name` | title | Description of the transaction |
| `Type` | select | `"Income"` or `"Expense"` |
| `Amount` | number | Positive value; sign handled by `Flow_Amount` formula |
| `date:Date:start` | date | ISO-8601 date or datetime (see Timezone Rules) |
| `date:Date:is_datetime` | integer | `1` if time included, `0` for date-only |
| `Category` | relation | JSON array of **one** Category page URL |
| `Account` | relation | JSON array of **one** Account page URL |
| `Monthly Report` | relation | JSON array of Monthly Report page URL (links transaction to a monthly report) |
| `Flow_Amount` | formula | **read-only** — do not write |
| `Income_Amount` | formula | **read-only** — Amount if Income, else 0 |
| `Expense_Amount` | formula | **read-only** — Amount if Expense, else 0 |

### Categories DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Category Name` | title | Human-readable label |
| `Monthly Budget` | number | Optional monthly spending cap |
| `Transactions` | relation | **read-only** (back-relation from Transactions) |
| `Total Spent` | rollup | **read-only** |

### Accounts DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Account Name` | title | e.g. 現金, 玉山, 國泰 |
| `Initial Balance` | number | Starting balance at account creation |
| `Transactions` | relation | **read-only** (back-relation) |
| `Net Flow` | rollup | **read-only** |
| `Current Balance` | formula | **read-only** |

### Fixed Expenses DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Item Name` | title | Name of the recurring expense |
| `Amount` | number | Full billing amount per cycle |
| `Billing Cycle` | select | `"Monthly"` or `"Annually"` |
| `date:Start Date:start` | date | First billing date (date-only) |
| `date:Start Date:is_datetime` | integer | Always `0` (date-only) |
| `Total Months` | number | Loan duration in months; `null` or `-1` = indefinite |
| `Category` | relation | JSON array of **one** Category page URL |
| `Monthly Report` | relation | JSON array of Monthly Report page URL (links to monthly reports) |
| `Monthly Amortization` | formula | **read-only** — `Amount` (Monthly) or `round(Amount / 12)` (Annually); indefinite when `Total Months` is null or -1 |

### Monthly Ledger — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Month` | title | Period label, e.g. `"2026-06"` |
| `date:Period Start:start` | date | First day of the month (date-only) |
| `date:Period Start:is_datetime` | integer | Always `0` |
| `Transactions` | relation | JSON array of Transactions page URLs for this month |
| `Fixed Expenses` | relation | JSON array of Fixed Expenses page URLs active this month |
| `Notes` | text | Free-form observations for the period |
| `Total Income` | rollup | **read-only** — sum of `Income_Amount` from linked Transactions |
| `Variable Spending` | rollup | **read-only** — sum of `Expense_Amount` from linked Transactions |
| `Fixed Burden` | rollup | **read-only** — sum of `Monthly Amortization` from linked Fixed Expenses |
| `Total Spending` | formula | **read-only** — `Variable Spending + Fixed Burden` |
| `Net` | formula | **read-only** — `Total Income − Variable Spending − Fixed Burden` |

**Page template ID**: `374e5198-eb31-8132-b454-cf0fff27966c` — apply with `notion_notion-update-page` (`apply_template` command) or use as `template_id` in `notion_notion-create-pages`.

## Reference Data (Pre-populated)

### Categories

Always **fetch or search** Categories DB before inserting a transaction to get the current page URLs. Do **not** hardcode URLs — they may change if categories are recreated.

| Category Name | Covers |
|---|---|
| 貸款 | Loan repayments (car loan, etc.) |
| 稅務 | Government taxes (fuel tax, registration tax) |
| 電信費 | Telecom bills (中華電信, mobile plans) |
| 訂閱服務 | Digital subscriptions (Github Copilot, streaming) |
| 娛樂 | Entertainment spending (games, outings) |
| 醫療 | Medical & dental expenses |

When a transaction does not fit any existing category, **create a new category first** (Step 3b) then link it.

### Accounts

| Account Name | Notes |
|---|---|
| 現金 | Default cash account |

Add new accounts as needed via the Accounts DB workflow.

## Timezone Rules

- **Workspace timezone**: GMT+8 (Asia/Taipei)
- **Datetime values** (time included): append `+08:00`
  - Correct: `"2026-06-05T09:00:00+08:00"`
  - Wrong: `"2026-06-05T09:00:00"` (treated as UTC → displays 8 h ahead)
- **Date-only values**: bare ISO date, no offset, `is_datetime` = `0`
  - Correct: `"2026-06-05"`

## Workflows

### Workflow A: Add a Transaction (Income or Expense)

#### Step 1 — Parse input

Extract from user input:

- `Item Name` — what was bought/received
- `Amount` — positive number
- `Type` — `"Income"` or `"Expense"` (default to `"Expense"` if unclear)
- `Date` — resolve relative dates against today in GMT+8
- `Category` — match to existing category (see table above); create new if unmatched
- `Account` — default to `現金` unless user specifies otherwise

#### Step 2 — Resolve Category URL

Search Categories DB to get the page URL:

```
notion_notion-search(
  query = "<category name>",
  data_source_url = "collection://374e5198-eb31-80aa-abab-000bc47a37a7"
)
```

Use the `url` field from the result.

#### Step 3 — Resolve Account URL

Search Accounts DB:

```
notion_notion-search(
  query = "<account name>",
  data_source_url = "collection://374e5198-eb31-80f3-9cc6-000b09106f59"
)
```

#### Step 3b — Create Category (if needed)

If no matching category exists, create it first:

```
notion_notion-create-pages(
  parent = { data_source_id: "374e5198-eb31-80aa-abab-000bc47a37a7" },
  pages = [{ properties: { "Category Name": "<name>" } }]
)
```

Use the returned URL for the transaction's `Category` relation.

#### Step 4 — Create transaction

```
notion_notion-create-pages(
  parent = { data_source_id: "374e5198-eb31-8047-9b3e-000bd1d10f27" },
  pages = [{
    properties: {
      "Item Name": "<name>",
      "Type": "Income" | "Expense",
      "Amount": <positive number>,
      "date:Date:start": "<ISO date or datetime+08:00>",
      "date:Date:is_datetime": 0 | 1,
      "Category": "[\"<category page URL>\"]",
      "Account": "[\"<account page URL>\"]"
    }
  }]
)
```

#### Step 5 — Confirm

Reply with: item name, amount, type, date, category, account, and the returned Notion URL.

### Workflow B: Add a Fixed Expense

Use this for **recurring** bills (subscriptions, loans, taxes). One entry per expense type — not per billing period.

#### Step 1 — Parse input

Extract:

- `Item Name`
- `Amount` — full amount per billing cycle
- `Billing Cycle` — `"Monthly"` or `"Annually"`
- `Start Date` — first billing date (date-only)
- `Category` — match to existing category; create new if unmatched
- `Total Months` — (optional) for finite-duration items like loans

#### Step 2 — Check for duplicates

Search Fixed Expenses DB before inserting:

```
notion_notion-search(
  query = "<item name>",
  data_source_url = "collection://374e5198-eb31-8061-b61f-000bda3ffef6"
)
```

If an entry with the same name already exists, **update** it with `notion_notion-update-page` instead of creating a duplicate.

#### Step 3 — Create (or update) entry

Create:

```
notion_notion-create-pages(
  parent = { data_source_id: "374e5198-eb31-8061-b61f-000bda3ffef6" },
  pages = [{
    properties: {
      "Item Name": "<name>",
      "Amount": <number>,
      "Billing Cycle": "Monthly" | "Annually",
      "date:Start Date:start": "<YYYY-MM-DD>",
      "date:Start Date:is_datetime": 0,
      "Category": "[\"<category page URL>\"]",
      "Total Months": <number> | null
    }
  }]
)
```

Update (if already exists):

```
notion_notion-update-page(
  page_id = "<existing page id>",
  command = "update_properties",
  properties = { "Amount": <new amount>, ... }
)
```

#### Step 4 — Confirm

Reply with item name, amount, billing cycle, start date, and monthly amortization note (Amount ÷ 12 for annual items).

### Workflow C: Add an Account

#### Step 1 — Parse input

Extract: Account Name, Initial Balance (default `0` if not given).

#### Step 2 — Check for duplicates

Search Accounts DB first. If found, offer to update instead.

#### Step 3 — Create

```
notion_notion-create-pages(
  parent = { data_source_id: "374e5198-eb31-80f3-9cc6-000b09106f59" },
  pages = [{
    properties: {
      "Account Name": "<name>",
      "Initial Balance": <number>
    }
  }]
)
```

### Workflow D: Query / Summarize

#### Spending by category (current month)

```
notion_notion-search(
  query = "<category or item>",
  data_source_url = "collection://374e5198-eb31-8047-9b3e-000bd1d10f27"
)
```

Then fetch individual pages to read Amount + Date.

#### Fixed expense monthly burden

Fetch Fixed Expenses DB and read the `Monthly Amortization` formula value from each page.

#### Account balance

Fetch the account page from Accounts DB. The `Current Balance` formula field shows: `Initial Balance + Net Flow`.

#### Category totals

Fetch a category page from Categories DB. The `Total Spent` rollup sums all linked transaction `Flow_Amount` values.

### Workflow E: Batch Migration (multiple rows)

When migrating many rows from an external source:

1. **Deduplicate first** — group by (Name + Frequency/Type). Keep the canonical record per item; drop same-month or same-day duplicates.
2. **Separate recurring vs one-time** — recurring → Fixed Expenses DB; one-time → Transactions DB.
3. **Re-map categories** — align source categories to the Categories DB reference table above. Create new categories for unmapped ones.
4. **Create reference data first** — insert Categories and Accounts before Transactions (relations require existing page URLs).
5. **Batch inserts** — use a single `notion_notion-create-pages` call per database (up to 100 pages per call).

### Workflow F: Create a Monthly Report

One row per month. Link existing Transactions and Fixed Expenses to compute aggregates automatically.

#### Step 1 — Create the report row from template

```
notion_notion-create-pages(
  parent = { data_source_id: "aa21aa5c-c752-43df-9f62-fa7b9d8c9259" },
  pages = [{
    template_id: "374e5198-eb31-8119-ab9a-fbb463936cd2",
    properties: {
      "Month": "2026-06",
      "date:Period Start:start": "2026-06-01",
      "date:Period Start:is_datetime": 0
    }
  }]
)
```

#### Step 2 — Link Transactions

Search Transactions DB for the target month, collect page URLs, then update the report:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Transactions": "[\"<tx url 1>\", \"<tx url 2>\", ...]"
  }
)
```

Alternatively, update each transaction directly to set its `Monthly Ledger` relation to the report page URL.

#### Step 3 — Link Fixed Expenses

Add active fixed expenses for the month:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Fixed Expenses": "[\"<fe url 1>\", \"<fe url 2>\", ...]"
  }
)
```

#### Step 4 — Computed properties auto-update

Once relations are set, all aggregates update automatically:

- `Total Income` = sum of Income transactions
- `Variable Spending` = sum of Expense transactions
- `Fixed Burden` = sum of monthly amortizations
- `Total Spending` = Variable Spending + Fixed Burden
- `Net` = Total Income − Total Spending

#### Step 5 — Confirm

Reply with the month, Total Income, Total Spending, Net, and the Notion URL of the report page.

## Validation

- [ ] No duplicate entries: searched target DB before inserting
- [ ] Category and Account relations are JSON arrays of page URLs, not IDs or names
- [ ] `Amount` is always a positive number regardless of Income/Expense
- [ ] Datetime values include `+08:00`; date-only values do not
- [ ] Fixed Expenses has one entry per recurring item (not one per billing period)
- [ ] `Total Months` is `null` or `-1` for indefinite recurring expenses (no end date)
- [ ] Monthly Ledger has one row per month; reuse existing row rather than duplicating
- [ ] Read-only formula/rollup properties were not written to

## Common Pitfalls

| Pitfall | Solution |
|---|---|
| Hardcoding category/account URLs | Always search or fetch the DB to resolve current URLs |
| Writing `Amount` as negative for Expense | Always positive — `Flow_Amount` formula handles the sign |
| Setting `is_datetime = 1` with a bare date string | Use `"YYYY-MM-DD"` + `is_datetime = 0`, or `"YYYY-MM-DDTHH:MM:SS+08:00"` + `is_datetime = 1` |
| Creating duplicate Fixed Expenses | Search before inserting; update if entry already exists |
| Linking Category by name string | Relations require a JSON array of page URLs, e.g. `["https://app.notion.com/p/..."]` |
| Creating one Fixed Expense row per month | Fixed Expenses are definitions, not per-period records; one row per recurring item |
| Creating a transaction without an Account | Account is required for balance rollup to work; default to 現金 if unspecified |
| Setting `Total Months` to `0` for indefinite | Use `null` or `-1`; `0` is ambiguous and may be treated as a zero-length loan |
| Creating duplicate Monthly Ledger rows for the same month | Search Monthly Ledger before creating; update existing row if found |
