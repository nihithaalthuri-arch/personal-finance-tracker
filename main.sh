#!/bin/bash
# Person 5: Main menu and module integration; macOS Bash 3.2 compatible.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_ROOT/modules/storage.sh"
source "$PROJECT_ROOT/modules/transactions.sh"
source "$PROJECT_ROOT/modules/budget.sh"
source "$PROJECT_ROOT/modules/reports.sh"

initialize_storage || { echo 'Cannot initialize data files.' >&2; exit 1; }

transactions_menu() {
    local choice
    while true; do
        printf '\nTRANSACTIONS\n1. Add income\n2. Add expense\n3. View all\n4. Edit\n5. Delete\n6. Back\n'
        read -r -p 'Choice: ' choice || return
        case "$choice" in
            1) add_transaction income ;;
            2) add_transaction expense ;;
            3) view_transactions ;;
            4) edit_transaction ;;
            5) delete_transaction ;;
            6) return ;;
            *) echo 'Invalid choice.' ;;
        esac
    done
}

budget_menu() {
    local choice
    while true; do
        printf '\nBUDGETS\n1. Set/update budget\n2. View all budgets\n3. Check budget\n4. Back\n'
        read -r -p 'Choice: ' choice || return
        case "$choice" in
            1) set_budget ;;
            2) view_budgets ;;
            3) check_budget ;;
            4) return ;;
            *) echo 'Invalid choice.' ;;
        esac
    done
}

main() {
    local choice
    while true; do
        printf '\n===== PERSONAL FINANCE TRACKER =====\n1. Transactions\n2. Budgets\n3. Monthly report\n4. Current balance\n5. Export monthly report\n6. Backup data\n7. Exit\n'
        read -r -p 'Choice: ' choice || exit 0
        case "$choice" in
            1) transactions_menu ;;
            2) budget_menu ;;
            3) report_menu ;;
            4) check_balance ;;
            5) export_report ;;
            6) backup_data ;;
            7) echo 'Goodbye!'; exit 0 ;;
            *) echo 'Invalid choice.' ;;
        esac
    done
}
main "$@"
