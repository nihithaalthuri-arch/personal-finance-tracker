# Personal Finance Tracker (Bash; macOS-compatible)

A five-person group project using the Bash shell and CSV data files. Runs on the Bash 3.2 supplied with macOS; no Homebrew needed.

## Start on a Mac

1. Open **Terminal** (`Cmd + Space`, type `Terminal`).
2. Unzip the project and `cd` into `personal-finance-tracker`.
3. Run `chmod +x main.sh tests/test.sh`.
4. Run `./main.sh`.
5. To run tests, execute `bash tests/test.sh`.

Data is saved in `data/transactions.csv` and `data/budgets.csv`. The app creates those files at first launch; don't delete the CSV headers. Data is local to the machine. **Never commit real financial data**. The sample `data/` folder is empty.

## Module ownership

- Person 1: `modules/transactions.sh` — add, view, edit, delete, balance.
- Person 2: `modules/budget.sh` — monthly category spending, limits, warnings.
- Person 3: `modules/reports.sh` — income/expense totals, category charts, export.
- Person 4: `modules/storage.sh` — initialization, CSV validation, file changes, backups.
- Person 5: `main.sh`, `tests/test.sh`, and README — menus, integration, automated tests.

## Shared data format

`transactions.csv`: `id,date,type,category,amount,description`.
`budgets.csv`: `month,category,limit`.

- Dates: `YYYY-MM-DD`; months: `YYYY-MM`.
- Monetary values: **positive whole rupees**, so no floating-point rounding issues.
- Categories and descriptions: cannot include commas, newlines, or start with spreadsheet-formula characters (`=`, `+`, `-`, `@`).
- IDs are unique within current records. Avoid editing CSV by hand while the program is running.

## Bash/macOS notes

Compatible with `/bin/bash` 3.2: no associative arrays, `mapfile`, GNU-specific `sed -i` or `date -d`. `awk`, `sort`, `mktemp`, and `date` are built into the standard macOS tools. Run with `bash`, **not** `sh`.

## Test and demo

Run `bash tests/test.sh` to verify transactions, editing, deleting, budgets, reporting, validation, and backups. For the viva, show adding income and an expense, a budget warning, a monthly report, and the final balance.

## Limitations

This is an educational single-user prototype, not a banking or accounting app. It does not encrypt saved data, does not support concurrent writes, assumes simple CSV fields, and stores whole INR values only. Backup supports creating backup copies; restoring should be done manually only after inspecting the backup.
