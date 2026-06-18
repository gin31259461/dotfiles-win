# Pre-Flight

Run this before every finance workflow. Store discovered values for the
session; do not reuse IDs or page URLs from earlier sessions.

## Find The Workspace

Search for the Financer page:

```text
notion_notion-search(query = "Financer")
```

Use the result titled `Financer`.

## Discover Databases

Fetch the Financer page:

```text
notion_notion-fetch(id = "<financer page id or url>")
```

Find the child page titled `Database`, then fetch it:

```text
notion_notion-fetch(id = $databasePageURL)
```

Extract each `<database>` tag and store both values:

- `$transactionsDS`: `collection://<uuid>`
- `$transactionsID`: `<uuid>`
- `$categoriesDS`: `collection://<uuid>`
- `$categoriesID`: `<uuid>`
- `$accountsDS`: `collection://<uuid>`
- `$accountsID`: `<uuid>`
- `$fixedExpensesDS`: `collection://<uuid>`
- `$fixedExpensesID`: `<uuid>`
- `$monthlyReportDS`: `collection://<uuid>`
- `$monthlyReportID`: `<uuid>`

Use `collection://<uuid>` for search `data_source_url`. Use `<uuid>` for
`parent.data_source_id` when creating pages.

## Resolve Relations Fresh

Before creating transactions, search current Categories and Accounts pages:

```text
notion_notion-search(query = "<category name>", data_source_url = $categoriesDS)
notion_notion-search(query = "<account name>", data_source_url = $accountsDS)
```

Use returned page URLs in relation arrays.
