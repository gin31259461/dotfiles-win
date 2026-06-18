# Add Fixed Expense

Use for recurring bills such as subscriptions, loans, and taxes. Keep one
entry per recurring item, not one per billing period.

Prerequisite: Pre-flight resolved `$fixedExpensesID`, `$fixedExpensesDS`,
`$categoriesID`, and `$categoriesDS`.

## Parse

Extract:

- `Item Name`
- `Amount`: full amount per billing cycle.
- `Billing Cycle`: `"Monthly"` or `"Annually"`.
- `Start Date`: first billing date, date-only.
- `Category`: match an existing category; create one if needed.
- `Total Months`: optional loan or finite-term duration.

## Deduplicate

Search by item name in Fixed Expenses. Scoped search may be incomplete, so use
workspace search plus ancestor-path verification when needed.

```text
notion_notion-search(query = "<item name>", data_source_url = $fixedExpensesDS)
notion_notion-search(query = "<item name>")
notion_notion-fetch(id = "<candidate page url>")
```

Only treat a result as a duplicate when its parent data source matches
`$fixedExpensesDS`. Update duplicates instead of creating new rows.

## Create Or Update

Create:

```text
notion_notion-create-pages(
  parent = { data_source_id: $fixedExpensesID },
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

Update:

```text
notion_notion-update-page(
  page_id = "<existing page id>",
  command = "update_properties",
  properties = { "Amount": <new amount>, ... }
)
```

Reply with item name, amount, billing cycle, start date, and monthly
amortization. Annual items amortize as `round(Amount / 12)`.
