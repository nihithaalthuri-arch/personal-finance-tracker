#!/bin/bash

# Main file for Personal Finance Tracker
# CLI, integration and testing - Ishitha

# Get the folder where this file is saved
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Set the folder where data will be stored
DATA_DIR="$PROJECT_DIR/data"
export DATA_DIR

# Load the other files
source "$PROJECT_DIR/storage.sh"
source "$PROJECT_DIR/transactions.sh"
source "$PROJECT_DIR/Budget.sh"
source "$PROJECT_DIR/reports.sh"

# Start the storage system
initialize_storage

# Display the main menu
show_menu() {
    echo
    echo "=================================="
    echo "      PERSONAL FINANCE TRACKER"
    echo "=================================="
    echo "1.  Add Income"
    echo "2.  Add Expense"
    echo "3.  View Transactions"
    echo "4.  Edit Transaction"
    echo "5.  Delete Transaction"
    echo "6.  Check Balance"
    echo "7.  Set Monthly Budget"
    echo "8.  View Monthly Budget"
    echo "9.  Generate Monthly Report"
    echo "10. Export Monthly Report"
    echo "11. Backup Data"
    echo "12. Restore Data"
    echo "13. Exit"
    echo "=================================="
}

# Wait for the user before showing the menu again
pause() {
    echo
    read -r -p "Press Enter to continue..." answer
}

# Restore data from a backup folder
restore_backup() {
    echo
    echo "Backup folders:"
    ls -d "$BACKUP_DIR"/backup_* 2>/dev/null

    read -r -p "Enter backup folder path: " folder

    if [ -z "$folder" ]; then
        echo "Restore cancelled."
    elif restore_data "$folder"; then
        echo "Data restored successfully."
    else
        echo "Could not restore data. Please check the folder path."
    fi
}

# Main program
while true
do
    show_menu
    read -r -p "Enter your choice: " choice

    case "$choice" in
        1)
            add_transaction "income"
            pause
            ;;
        2)
            add_transaction "expense"
            pause
            ;;
        3)
            view_transactions
            pause
            ;;
        4)
            edit_transaction
            pause
            ;;
        5)
            delete_transaction
            pause
            ;;
        6)
            check_balance
            pause
            ;;
        7)
            set_budget
            pause
            ;;
        8)
            view_budgets
            pause
            ;;
        9)
            report_menu
            pause
            ;;
        10)
            export_report
            pause
            ;;
        11)
            backup_data
            pause
            ;;
        12)
            restore_backup
            pause
            ;;
        13)
            echo "Thank you for using Personal Finance Tracker!"
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number from 1 to 13."
            pause
            ;;
    esac
done
