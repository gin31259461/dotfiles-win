# Database Reference

All databases live under `Financer/Database`. Discover IDs with Pre-flight.

## Transactions DB

Writable properties:

- `Item Name`: title.
- `Type`: select, `"Income"` or `"Expense"`.
- `Amount`: positive number; sign is handled by `Flow_Amount`.
- `date:Date:start`: ISO date or datetime.
- `date:Date:is_datetime`: `1` for datetime, `0` for date-only.
- `Category`: relation array with one Category page URL.
- `Account`: relation array with one Account page URL.
- `Monthly Report`: relation array with one Monthly Report page URL.

Read-only:

- `Flow_Amount`: signed amount formula.
- `Income_Amount`: amount for income, otherwise `0`.
- `Expense_Amount`: amount for expense, otherwise `0`.

## Categories DB

Writable properties:

- `Category Name`: title.
- `Monthly Budget`: optional number.

Read-only:

- `Transactions`: back-relation from Transactions.
- `Total Spent`: rollup.

## Accounts DB

Writable properties:

- `Account Name`: title, such as `現金`, `玉山`, or `國泰`.
- `Initial Balance`: starting balance.

Read-only:

- `Transactions`: back-relation.
- `Net Flow`: rollup.
- `Current Balance`: formula.

## Fixed Expenses DB

Writable properties:

- `Item Name`: title.
- `Amount`: full billing amount per cycle.
- `Billing Cycle`: select, `"Monthly"` or `"Annually"`.
- `date:Start Date:start`: first billing date.
- `date:Start Date:is_datetime`: always `0`.
- `Total Months`: duration; `null` or `-1` means indefinite.
- `Category`: relation array with one Category page URL.
- `Monthly Report`: relation array with Monthly Report page URLs.

Read-only:

- `Monthly Amortization`: formula. Monthly rows use `Amount`; annual rows use
  `round(Amount / 12)`.

## Monthly Report DB

Writable properties:

- `Month`: title, such as `2026-06`.
- `date:Period Start:start`: first day of month.
- `date:Period Start:is_datetime`: always `0`.
- `Transactions`: relation array with Transactions page URLs.
- `Fixed Expenses`: relation array with Fixed Expenses page URLs.
- `Notes`: text.

Read-only:

- `Total Income`: rollup of linked `Income_Amount`.
- `Variable Spending`: rollup of linked `Expense_Amount`.
- `Fixed Burden`: rollup of linked `Monthly Amortization`.
- `Total Spending`: formula for variable spending plus fixed burden.
- `Net`: formula for income minus total spending.
