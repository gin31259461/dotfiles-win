# Workflow B: Add a Fixed Expense

Use for **recurring** bills (subscriptions, loans, taxes). One entry per expense type — not per billing period.

**Pre-requisite**: Pre-flight completed (`$fixedExpensesDS`, `$categoriesDS` resolved).

## Step 1 — Parse input

Extract:

- `Item Name`
- `Amount` — full amount per billing cycle
- `Billing Cycle` — `"Monthly"` or `"Annually"`
- `Start Date` — first billing date (date-only)
- `Category` — match to existing category; create new if unmatched
- `Total Months` — (optional) for finite-duration items like loans

## Step 2 — Check for duplicates

Use a two-pass approach since `data_source_url` scoped search is unreliable:

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

If an entry with the same name already exists, **update** it instead of creating a duplicate.

## Step 3 — Create (or update) entry

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

## Step 4 — Confirm

Reply with item name, amount, billing cycle, start date, and monthly amortization note (Amount ÷ 12 for annual items).
