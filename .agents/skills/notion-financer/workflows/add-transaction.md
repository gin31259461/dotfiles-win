# Add Transaction

Use for one-time income or expense records.

Prerequisite: Pre-flight resolved `$transactionsID`, `$categoriesID`,
`$categoriesDS`, `$accountsID`, and `$accountsDS`.

## Parse

Extract:

- `Item Name`: what was bought or received.
- `Amount`: positive number.
- `Type`: `"Income"` or `"Expense"`; default to `"Expense"` if unclear.
- `Date`: resolve relative dates in GMT+8.
- `Category`: match an existing category; create one if needed.
- `Account`: default to `現金` unless the user specifies another account.

## Resolve Category And Account

Search current pages and use result URLs:

```text
notion_notion-search(query = "<category name>", data_source_url = $categoriesDS)
notion_notion-search(query = "<account name>", data_source_url = $accountsDS)
```

If the category is missing, create it first:

```text
notion_notion-create-pages(
  parent = { data_source_id: $categoriesID },
  pages = [{ properties: { "Category Name": "<name>" } }]
)
```

## Create Transaction

```text
notion_notion-create-pages(
  parent = { data_source_id: $transactionsID },
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

Reply with item name, amount, type, date, category, account, and Notion URL.
