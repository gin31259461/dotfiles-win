# Workflow A: Add a Transaction (Income or Expense)

**Pre-requisite**: Pre-flight completed (`$transactionsDS`, `$categoriesDS`, `$accountsDS` resolved).

## Step 1 — Parse input

Extract from user input:

- `Item Name` — what was bought/received
- `Amount` — positive number
- `Type` — `"Income"` or `"Expense"` (default to `"Expense"` if unclear)
- `Date` — resolve relative dates against today in GMT+8
- `Category` — match to existing category; create new if unmatched
- `Account` — default to `現金` unless user specifies otherwise

## Step 2 — Resolve Category URL

Search Categories DB to get the page URL:

```
notion_notion-search(
  query = "<category name>",
  data_source_url = $categoriesDS
)
```

Use the `url` field from the result.

## Step 3 — Resolve Account URL

Search Accounts DB:

```
notion_notion-search(
  query = "<account name>",
  data_source_url = $accountsDS
)
```

## Step 3b — Create Category (if needed)

If no matching category exists, create it first:

```
notion_notion-create-pages(
  parent = { data_source_id: $categoriesDS },
  pages = [{ properties: { "Category Name": "<name>" } }]
)
```

Use the returned URL for the transaction's `Category` relation.

## Step 4 — Create transaction

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

## Step 5 — Confirm

Reply with: item name, amount, type, date, category, account, and the returned Notion URL.
