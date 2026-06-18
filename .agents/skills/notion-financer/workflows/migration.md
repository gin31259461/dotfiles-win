# Batch Migration

Use for importing many finance rows from another source.

1. Deduplicate by name plus frequency or type. Keep the canonical record.
2. Split recurring rows into Fixed Expenses and one-time rows into Transactions.
3. Map source categories to existing Categories. Create missing categories.
4. Create Categories and Accounts before rows that reference them.
5. Batch inserts with one `notion_notion-create-pages` call per database.
   Limit each call to 100 pages.
