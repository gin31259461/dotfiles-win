# Workflow D: Query / Summarize

**Pre-requisite**: Pre-flight completed (relevant DBs resolved).

## Spending by category (current month)

```
notion_notion-search(
  query = "<category or item>",
  data_source_url = $transactionsDS
)
```

Then fetch individual pages to read Amount + Date.

## Fixed expense monthly burden

Find all pages in Fixed Expenses DB using the two-pass approach (workspace search + ancestor-path verification). For each verified page, read `Amount` and `Billing Cycle` to compute Monthly Amortization (Monthly = Amount, Annually = round(Amount / 12)). Sum all qualifying MA values where Amount > 0.

## Account balance

Fetch the account page from Accounts DB. The `Current Balance` formula field shows: `Initial Balance + Net Flow`.

## Category totals

Fetch a category page from Categories DB. The `Total Spent` rollup sums all linked transaction `Flow_Amount` values.
