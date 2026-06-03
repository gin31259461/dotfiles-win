---
name: notion-personal-finance
description: Manages the Personal Finance Notion workspace — recording transactions, managing fixed expenses, querying spending summaries, and maintaining categories and accounts. Use when the user wants to log income or expenses, add/update recurring bills, check balances, or report on spending.
---

# Notion Personal Finance

Provides a complete workflow for interacting with the Personal Finance Notion workspace. The system consists of five linked databases. This skill covers every operation: inserting transactions, managing fixed expenses, maintaining reference data (categories, accounts), generating monthly reports, and summarizing finances.

**Critical**: Do NOT hardcode any IDs (data source, template, or page). Always discover them dynamically via the Pre-flight workflow below.

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

## Pre-flight: Discover Database IDs

Before any workflow, discover all database data source URLs dynamically by fetching the **Personal Finance** page:

### Step 1 — Find the Personal Finance page

Search for it by name:

```
notion_notion-search(query = "Personal Finance")
```

Look for the result with title "Personal Finance". Use its `id` or `url`.

### Step 2 — Fetch and extract database entries

Fetch the page to reveal linked databases:

```
notion_notion-fetch(id = "<personal finance page id/url>")
```

The response contains `<database>` tags with `data-source-url` attributes:

```xml
<database data-source-url="collection://<uuid>">Transactions DB</database>
<database data-source-url="collection://<uuid>">Categories DB</database>
<database data-source-url="collection://<uuid>">Accounts DB</database>
<database data-source-url="collection://<uuid>">Fixed Expenses DB</database>
<database data-source-url="collection://<uuid>">Monthly Report DB</database>
```

Extract both forms for each:

| Variable | For search `data_source_url` | For create `parent.data_source_id` |
|---|---|---|
| `$transactionsDS` | `collection://<uuid>` | `<uuid>` |
| `$categoriesDS` | `collection://<uuid>` | `<uuid>` |
| `$accountsDS` | `collection://<uuid>` | `<uuid>` |
| `$fixedExpensesDS` | `collection://<uuid>` | `<uuid>` |
| `$monthlyReportDS` | `collection://<uuid>` | `<uuid>` |

### Step 3 — Discover the Monthly Report template

Fetch the Monthly Report DB to find template pages:

```
notion_notion-fetch(id = "<monthly report db page url>")
```

Look for `<templates>` section in the response. Extract the template page ID (UUID) — this is the `template_id` to use when creating monthly reports. If no templates section exists, fetch each page in the Monthly Report DB to find one with title containing "Template" and use its ID.

### Step 4 — Discover Category and Account page URLs

Before creating transactions, always search the Categories DB and Accounts DB to resolve current page URLs (do not reuse cached URLs from previous sessions):

```
notion_notion-search(query = "<category name>", data_source_url = $categoriesDS)
notion_notion-search(query = "<account name>", data_source_url = $accountsDS)
```

## Database Reference

All five databases live under the **💰 Personal Finance** page. Discover their IDs dynamically (see Pre-flight above).

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

The Monthly Report DB has a template page — discover it dynamically via Pre-flight Step 3.

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

### Workflow 0: Pre-flight (run first)

Before any workflow below, run the Pre-flight workflow above to discover all database data source IDs and store them as variables (`$transactionsDS`, `$categoriesDS`, `$accountsDS`, `$fixedExpensesDS`, `$monthlyReportDS`, `$templateId`).

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
  data_source_url = $categoriesDS
)
```

Use the `url` field from the result.

#### Step 3 — Resolve Account URL

Search Accounts DB:

```
notion_notion-search(
  query = "<account name>",
  data_source_url = $accountsDS
)
```

#### Step 3b — Create Category (if needed)

If no matching category exists, create it first:

```
notion_notion-create-pages(
  parent = { data_source_id: $categoriesDS },
  pages = [{ properties: { "Category Name": "<name>" } }]
)
```

Use the returned URL for the transaction's `Category` relation.

#### Step 4 — Create transaction

```
notion_notion-create-pages(
  parent = { data_source_id: $transactionsDS },
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

Search Fixed Expenses DB before inserting. `data_source_url` scoped search is unreliable, so use a two-pass approach:

**Pass 1** — Try scoped search:

```
notion_notion-search(
  query = "<item name>",
  data_source_url = $fixedExpensesDS
)
```

**Pass 2** — If Pass 1 returns zero results or `type` is `workspace_search`, fall back to workspace search + ancestor-path verification:

```
notion_notion-search(query = "<item name>")
# For each result, fetch and check:
# <parent-data-source url="collection://<matches $fixedExpensesDS>" name="Fixed Expenses DB"/>
```

If an entry with the same name already exists, **update** it with `notion_notion-update-page` instead of creating a duplicate.

#### Step 3 — Create (or update) entry

Create:

```
notion_notion-create-pages(
  parent = { data_source_id: $fixedExpensesDS },
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
  parent = { data_source_id: $accountsDS },
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
  data_source_url = $transactionsDS
)
```

Then fetch individual pages to read Amount + Date.

#### Fixed expense monthly burden

Find all pages in the Fixed Expenses DB using the same two-pass approach as Workflow F Step 2 (workspace search + ancestor-path verification). For each verified page, read `Amount` and `Billing Cycle` to compute Monthly Amortization (Monthly = Amount, Annually = round(Amount / 12)). Sum all qualifying MA values where Amount > 0.

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

### Workflow F: Create a Monthly Report (Auto-Linking)

One row per month. **All** fixed expenses and month transactions are auto-linked dynamically — no manual relation setup and no hardcoded lists.

#### Step 0 — Pre-flight

Ensure `$monthlyReportDS`, `$fixedExpensesDS`, `$transactionsDS`, and `$templateId` are resolved (run Workflow 0 if needed).

#### Step 1 — Discover and apply the template

Create the report row using the dynamically discovered template:

```
notion_notion-create-pages(
  parent = { data_source_id: $monthlyReportDS },
  pages = [{
    template_id: $templateId,
    properties: {
      "Month": "2026-06",
      "date:Period Start:start": "2026-06-01",
      "date:Period Start:is_datetime": 0
    }
  }]
)
```

#### Step 2 — Auto-link ALL Fixed Expenses (Monthly Amortization > 0)

Find all pages in the Fixed Expenses DB. **Do not** rely solely on `data_source_url` in `notion_notion-search` — it has known unreliability and may return zero results even when pages exist. Use a two-pass approach:

**Pass 1** — Try scoped search (fast path):

```
notion_notion-search(
  query = "a",
  data_source_url = $fixedExpensesDS,
  page_size = 25
)
```

If it returns pages with `type: "page"`, verify each belongs to `$fixedExpensesDS` via ancestor-path check, then collect.

**Pass 2** — Fall back to workspace search + verification if Pass 1 returned zero results or `type` is `workspace_search`:

Search the workspace broadly for known fixed expense names (e.g. "貸款", "電信", "Copilot", "燃料", "牌照") or simply pages created near the finance setup date. For each candidate, fetch the page and inspect its `<ancestor-path>`:

```
notion_notion-fetch(id = "<candidate page url>")
# Check if response contains:
# <parent-data-source url="collection://<matches $fixedExpensesDS>" name="Fixed Expenses DB"/>
```

Only include pages that pass this verification.

For each verified Fixed Expense page, read its `Amount` and `Billing Cycle` to determine `Monthly Amortization`:

- `Monthly` cycle → MA = `Amount` (> 0 if Amount > 0)
- `Annually` cycle → MA = `round(Amount / 12)` (> 0 if Amount > 0)

**Only link fixed expenses where Monthly Amortization > 0.** (If Amount is 0 or null, skip it.)

Collect all qualifying page URLs and link them to the report:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Fixed Expenses": "[\"<url 1>\", \"<url 2>\", ...]"
  }
)
```

This links every qualifying fixed expense regardless of count — no hardcoded list.

#### Step 3 — Auto-link ALL month Transactions

Search Transactions DB for transactions within the target month. **Do not** rely solely on `data_source_url` in `notion_notion-search` — it has known unreliability and may return zero results even when pages exist. Use a two-pass approach:

**Pass 1** — Try scoped search (fast path):

```
notion_notion-search(
  query = "YYYY-MM",
  data_source_url = $transactionsDS,
  page_size = 25
)
```

If it returns pages with `type: "page"`, verify each via ancestor-path check (response contains `<parent-data-source url="collection://...">` matching `$transactionsDS`), then collect their URLs and skip to linking below.

**Pass 2** — Fall back to workspace search + verification if Pass 1 returned zero results or `type` is `workspace_search`:

Search the workspace broadly. Try multiple queries to maximize coverage:

- The month label: `notion_notion-search(query = "YYYY-MM")`
- Known transaction item names (e.g. "加油", "Income", "Expense")
- Recent pages by scanning various terms

For each candidate result, fetch the page and inspect its `<ancestor-path>`. Only include pages whose ancestor chain contains a `<parent-data-source>` with `url` matching `$transactionsDS` AND a `date:Date:start` value within the target month:

```
notion_notion-fetch(id = "<candidate page url>")
# Check if response contains:
# <parent-data-source url="collection://<matches $transactionsDS>" name="Transactions DB"/>
# AND properties.date:Date:start starts with "YYYY-MM"
```

Collect all verified transaction page URLs and link them to the report:

```
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Transactions": "[\"<tx url 1>\", \"<tx url 2>\", ...]"
  }
)
```

If no transactions exist yet for the month, skip linking — they can be linked later as transactions are added.

#### Step 4 — Computed properties auto-update

Once relations are set, all aggregates update automatically:

- `Total Income` = sum of Income transactions
- `Variable Spending` = sum of Expense transactions
- `Fixed Burden` = sum of Monthly Amortization from all linked Fixed Expenses
- `Total Spending` = Variable Spending + Fixed Burden
- `Net` = Total Income − Total Spending

#### Step 5 — Confirm

Reply with the month, Total Income, Total Spending, Net, the full Fixed Burden breakdown (each expense + amount), and the Notion URL of the report page.

## Validation

- [ ] Ran Pre-flight to discover all IDs — no hardcoded UUIDs used
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
| Hardcoding data source IDs | Always run Pre-flight to discover IDs dynamically — they can change if databases are recreated |
| Hardcoding template IDs | Discover template page ID from Monthly Report DB each session |
| Hardcoding category/account URLs | Always search or fetch the DB to resolve current URLs |
| Writing `Amount` as negative for Expense | Always positive — `Flow_Amount` formula handles the sign |
| Setting `is_datetime = 1` with a bare date string | Use `"YYYY-MM-DD"` + `is_datetime = 0`, or `"YYYY-MM-DDTHH:MM:SS+08:00"` + `is_datetime = 1` |
| Creating duplicate Fixed Expenses | Search before inserting; update if entry already exists |
| Linking Category by name string | Relations require a JSON array of page URLs, e.g. `["https://app.notion.com/p/..."]` |
| Creating one Fixed Expense row per month | Fixed Expenses are definitions, not per-period records; one row per recurring item |
| Creating a transaction without an Account | Account is required for balance rollup to work; default to `現金` if user does not specify |
| Setting `Total Months` to `0` for indefinite | Use `null` or `-1`; `0` is ambiguous and may be treated as a zero-length loan |
| Creating duplicate Monthly Ledger rows for the same month | Search Monthly Ledger before creating; update existing row if found |
| `notion_notion-search` with `data_source_url` returns zero results despite pages existing | `data_source_url` scoped search is unreliable. Use two-pass fallback: workspace search + ancestor-path verification. Applies to ALL database searches (Transactions, Fixed Expenses, Categories, Accounts). See Workflow F Steps 2-3 for the pattern |
| Linking fixed expenses with $0 or null Monthly Amortization | Only link fixed expenses where Monthly Amortization > 0. Check `Amount` > 0 before computing MA (Monthly = Amount, Annually = round(Amount / 12)) |
