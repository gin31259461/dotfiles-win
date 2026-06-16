# Workflow C: Add an Account

**Pre-requisite**: Pre-flight completed (`$accountsDS` resolved).

## Step 1 — Parse input

Extract: Account Name, Initial Balance (default `0` if not given).

## Step 2 — Check for duplicates

Search Accounts DB first. If found, offer to update instead.

## Step 3 — Create

```
notion_notion-create-pages(
  parent = { data_source_id: $accountsDS },
  pages = [{
    properties: {
      "Account Name": "<name>",
      "Initial Balance": <number>
    }
  }]
)
```
