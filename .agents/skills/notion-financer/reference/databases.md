# Database Reference

All five databases live under the **Financer/Database** page. Discover their IDs dynamically via the Pre-flight workflow.

## Transactions DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Item Name` | title | Description of the transaction |
| `Type` | select | `"Income"` or `"Expense"` |
| `Amount` | number | Positive value; sign handled by `Flow_Amount` formula |
| `date:Date:start` | date | ISO-8601 date or datetime (see Timezone Rules) |
| `date:Date:is_datetime` | integer | `1` if time included, `0` for date-only |
| `Category` | relation | JSON array of **one** Category page URL |
| `Account` | relation | JSON array of **one** Account page URL |
| `Monthly Report` | relation | JSON array of Monthly Report page URL (links transaction to a monthly report) |
| `Flow_Amount` | formula | **read-only** — do not write |
| `Income_Amount` | formula | **read-only** — Amount if Income, else 0 |
| `Expense_Amount` | formula | **read-only** — Amount if Expense, else 0 |

## Categories DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Category Name` | title | Human-readable label |
| `Monthly Budget` | number | Optional monthly spending cap |
| `Transactions` | relation | **read-only** (back-relation from Transactions) |
| `Total Spent` | rollup | **read-only** |

## Accounts DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Account Name` | title | e.g. 現金, 玉山, 國泰 |
| `Initial Balance` | number | Starting balance at account creation |
| `Transactions` | relation | **read-only** (back-relation) |
| `Net Flow` | rollup | **read-only** |
| `Current Balance` | formula | **read-only** |

## Fixed Expenses DB — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Item Name` | title | Name of the recurring expense |
| `Amount` | number | Full billing amount per cycle |
| `Billing Cycle` | select | `"Monthly"` or `"Annually"` |
| `date:Start Date:start` | date | First billing date (date-only) |
| `date:Start Date:is_datetime` | integer | Always `0` (date-only) |
| `Total Months` | number | Loan duration in months; `null` or `-1` = indefinite |
| `Category` | relation | JSON array of **one** Category page URL |
| `Monthly Report` | relation | JSON array of Monthly Report page URL (links to monthly reports) |
| `Monthly Amortization` | formula | **read-only** — `Amount` (Monthly) or `round(Amount / 12)` (Annually); indefinite when `Total Months` is null or -1 |

## Monthly Report — Writable Properties

| Property | Type | Notes |
|---|---|---|
| `Month` | title | Period label, e.g. `"2026-06"` |
| `date:Period Start:start` | date | First day of the month (date-only) |
| `date:Period Start:is_datetime` | integer | Always `0` |
| `Transactions` | relation | JSON array of Transactions page URLs for this month |
| `Fixed Expenses` | relation | JSON array of Fixed Expenses page URLs active this month |
| `Notes` | text | Free-form observations for the period |
| `Total Income` | rollup | **read-only** — sum of `Income_Amount` from linked Transactions |
| `Variable Spending` | rollup | **read-only** — sum of `Expense_Amount` from linked Transactions |
| `Fixed Burden` | rollup | **read-only** — sum of `Monthly Amortization` from linked Fixed Expenses |
| `Total Spending` | formula | **read-only** — `Variable Spending + Fixed Burden` |
| `Net` | formula | **read-only** — `Total Income − Variable Spending − Fixed Burden` |

The Monthly Report DB has a template page — discover it dynamically via Pre-flight Step 3.
