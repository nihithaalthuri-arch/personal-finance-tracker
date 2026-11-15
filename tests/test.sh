#!/bin/bash
# Person 5: Automated smoke/integration tests.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FINANCE_DATA_DIR="$(mktemp -d "${TMPDIR:-/tmp}/finance-test.XXXXXX")"
export FINANCE_DATA_DIR
trap 'rm -rf "$FINANCE_DATA_DIR"' EXIT
source "$PROJECT_ROOT/modules/storage.sh"
source "$PROJECT_ROOT/modules/transactions.sh"
source "$PROJECT_ROOT/modules/budget.sh"
source "$PROJECT_ROOT/modules/reports.sh"
initialize_storage
save_transaction income Salary 10000 Internship
[ "$LAST_TRANSACTION_ID" = 1 ]
save_transaction expense Food 250 Lunch
[ "$LAST_TRANSACTION_ID" = 2 ]
[ "$(calculate_spending "$(date +%Y-%m)" Food)" = 250 ]
save_budget_record "$(date +%Y-%m)" Food 1000
[ "$(awk -F, 'END {print NR}' "$BUDGETS_FILE")" = 2 ]
save_budget_record "$(date +%Y-%m)" Food 900
[ "$(awk -F, 'END {print NR}' "$BUDGETS_FILE")" = 2 ]
update_transaction_record 2 expense Food 300 Dinner
[ "$(calculate_spending "$(date +%Y-%m)" Food)" = 300 ]
monthly_report "$(date +%Y-%m)" | grep -q 'Net savings: INR 9700'
delete_transaction_record 2
! transaction_exists 2
[ "$(calculate_spending "$(date +%Y-%m)" Food)" = 0 ]
if save_transaction expense Food nope Fail; then echo 'Invalid amount accepted!' >&2; exit 1; fi
backup_data | grep -q 'Backup saved to:'
echo 'All tests passed.'
