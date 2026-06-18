# Monthly Report

Use one row per month. Reuse an existing row for the same month when present.
Relations drive the computed totals; do not write rollups or formulas.

Prerequisite: Pre-flight resolved `$monthlyReportID`, `$monthlyReportDS`,
`$fixedExpensesDS`, and `$transactionsDS`.

## Find Or Create Report

Search for the target `YYYY-MM` month in Monthly Report. Verify candidates by
ancestor path when scoped search is incomplete.

Create the row only when no verified report exists:

```text
notion_notion-create-pages(
  parent = { data_source_id: $monthlyReportID },
  pages = [{
    properties: {
      "Month": "YYYY-MM",
      "date:Period Start:start": "YYYY-MM-01",
      "date:Period Start:is_datetime": 0
    }
  }]
)
```

## Link Fixed Expenses

Collect verified Fixed Expenses pages. Include only rows with positive monthly
amortization:

- Monthly cycle: `Amount`
- Annual cycle: `round(Amount / 12)`

Use scoped search first. Fall back to workspace search plus ancestor-path
verification when results are empty, incomplete, or typed as workspace search.

```text
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Fixed Expenses": "[\"<url 1>\", \"<url 2>\"]"
  }
)
```

## Link Transactions

Search Transactions for the target month. Fetch and verify candidates, then
link every transaction in that month. If none are found, leave the relation
empty.

```text
notion_notion-update-page(
  page_id = "<report page id>",
  command = "update_properties",
  properties = {
    "Transactions": "[\"<tx url 1>\", \"<tx url 2>\"]"
  }
)
```

## Confirm

After relations update, computed properties refresh automatically:

- `Total Income`: sum of linked income transactions.
- `Variable Spending`: sum of linked expense transactions.
- `Fixed Burden`: sum of linked fixed expense amortization.
- `Total Spending`: variable spending plus fixed burden.
- `Net`: total income minus total spending.

Reply with month, income, spending, net, fixed burden breakdown, and Notion URL.
