# Workflow E: Batch Migration (multiple rows)

When migrating many rows from an external source:

1. **Deduplicate first** — group by (Name + Frequency/Type). Keep the canonical record per item; drop same-month or same-day duplicates.
2. **Separate recurring vs one-time** — recurring → Fixed Expenses DB; one-time → Transactions DB.
3. **Re-map categories** — align source categories to the Categories DB reference table. Create new categories for unmapped ones.
4. **Create reference data first** — insert Categories and Accounts before Transactions (relations require existing page URLs).
5. **Batch inserts** — use a single `notion_notion-create-pages` call per database (up to 100 pages per call).
