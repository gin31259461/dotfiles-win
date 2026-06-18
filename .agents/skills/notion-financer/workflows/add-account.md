# Add Account

Prerequisite: Pre-flight resolved `$accountsID` and `$accountsDS`.

## Workflow

1. Extract `Account Name` and `Initial Balance`; default balance to `0`.
2. Search Accounts for duplicates. If found, update only when the user agrees.
3. Create the account.

```text
notion_notion-create-pages(
  parent = { data_source_id: $accountsID },
  pages = [{
    properties: {
      "Account Name": "<name>",
      "Initial Balance": <number>
    }
  }]
)
```
