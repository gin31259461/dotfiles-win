# Query And Summarize

Prerequisite: Pre-flight resolved the relevant databases.

## Spending By Category

Search Transactions by category or item, then fetch matching pages to read
`Amount`, `Type`, `Date`, and relations.

```text
notion_notion-search(
  query = "<category or item>",
  data_source_url = $transactionsDS
)
```

## Fixed Expense Burden

Find Fixed Expenses with scoped search. If results are empty or incomplete, use
workspace search plus ancestor-path verification. For each verified page:

- Monthly: monthly amortization is `Amount`.
- Annually: monthly amortization is `round(Amount / 12)`.
- Ignore rows with missing or zero Amount.

## Account Balance

Fetch the account page. `Current Balance` is a read-only formula:
`Initial Balance + Net Flow`.

## Category Totals

Fetch the category page. `Total Spent` is a read-only rollup over linked
transaction `Flow_Amount` values.
