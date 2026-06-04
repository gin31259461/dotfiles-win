# Workflow F: Create a Monthly Report

One row per month. All fixed expenses and month transactions are auto-linked dynamically — no manual relation setup.

**Pre-requisite**: Pre-flight completed (`$monthlyReportDS`, `$fixedExpensesDS`, `$transactionsDS` resolved).

## Step 1 — Link All Fixed Expenses (Monthly Amortization > 0)

**Do not** rely solely on `data_source_url` in `notion_notion-search` — use a two-pass approach:

**Pass 1** — Try scoped search (fast path):

```
notion_notion-search(
  query = "",
  data_source_url = $fixedExpensesDS,
  page_size = 25
)
```

If it returns pages with `type: "page"`, verify each via ancestor-path check, then collect.

**Pass 2** — Fall back to workspace search + verification if Pass 1 returned zero results or `type` is `workspace_search`:

Search the workspace broadly for known fixed expense names (e.g. "貸款", "電信", "Copilot", "燃料", "牌照"). For each candidate, fetch the page and inspect its `<ancestor-path>`:

```
notion_notion-fetch(id = "<candidate page url>")
# Check if response contains:
# <parent-data-source url="collection://<matches $fixedExpensesDS>" name="Fixed Expenses DB"/>
```

Only include pages that pass this verification.

For each verified Fixed Expense page, compute Monthly Amortization:

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

## Step 2 — Link All Month Transactions

**Pass 1 — Initial Database Query (Fast Path):**

Instead of a full-text search, query the database directly using a date filter to ensure exact matches and avoid missing properties.

```
notion_notion-database-query(
    database_id = $transactionsDS,
    filter = {
        "property": "Date",
        "date": {
        "on_or_after": "YYYY-MM-01",
        "before": "YYYY-MM+1-01" // e.g., if target is 2026-06, use 2026-07-01 here
    }
    },
    page_size = 100
)
```

Collect all returned pages. If `has_more` is `false`, skip to the linking phase. If `has_more` is `true`, proceed to Pass 2.

**Pass 2 — Handle Pagination Loop (Fallback/Completion):**

If the transaction count exceeds 100, the API will return `has_more: true` and a `next_cursor`. You MUST use this cursor to fetch the remaining data.

Initialize a list with the results from Pass 1, then execute the following loop until `has_more` is `false`:

notion_notion-database-query(
database_id = $transactionsDS,
filter = { /*Use the exact same date filter as Pass 1*/ },
page_size = 100,
start_cursor = "<next_cursor from the previous API response>"
)

1. Append the newly fetched pages to your main list.
2. Update your current `next_cursor` with the one from the new response.
3. If `has_more` is still `true`, repeat this step.

**Final Step — Link to Report:**

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

If the fetched transaction list is completely empty for the target month, simply skip the linking process.

## Step 3 — Computed Properties Auto-update

Once relations are set, all aggregates update automatically:

- `Total Income` = sum of Income transactions
- `Variable Spending` = sum of Expense transactions
- `Fixed Burden` = sum of Monthly Amortization from all linked Fixed Expenses
- `Total Spending` = Variable Spending + Fixed Burden
- `Net` = Total Income − Total Spending

## Step 4 — Confirm

Reply with the month, Total Income, Total Spending, Net, the full Fixed Burden breakdown (each expense + amount), and the Notion URL of the report page.
