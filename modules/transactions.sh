

#!/bin/bash

# PERSON 1 - TRANSACTION MANAGEMENT
# Personal Finance Tracker
# Compatible with macOS Bash 3.2

# FEATURE 1: Add income or expense
add_transaction() {
    local type="$1"
    local category amount description

    echo
    echo "===== ADD TRANSACTION ====="

    read -r -p "Category: " category
    read -r -p "Amount (whole INR): " amount
    read -r -p "Description: " description

    if save_transaction "$type" "$category" \
        "$amount" "$description"; then

        echo "Transaction #$LAST_TRANSACTION_ID saved."
    else
        echo "Invalid details."
        echo "Use a positive whole-number amount."
        echo "Do not use commas or newlines in text."
    fi
}

# FEATURE 2: View all transactions
view_transactions() {
    echo
    echo "===== TRANSACTION HISTORY ====="

    printf '%-5s %-12s %-8s %-15s %-10s %s\n' \
        "ID" "Date" "Type" "Category" "INR" "Description"

    awk -F, '
        NR > 1 {
            printf "%-5s %-12s %-8s %-15s %-10s %s\n", \
            $1, $2, $3, $4, $5, $6
            count++
        }
        END {
            if (count == 0)
                print "No transactions yet."
        }
    ' "$TRANSACTIONS_FILE"
}

# FEATURE 3: Delete a transaction
delete_transaction() {
    local id

    echo
    echo "===== DELETE TRANSACTION ====="

    read -r -p "Transaction ID to delete: " id

    if delete_transaction_record "$id"; then
        echo "Transaction deleted successfully."
    else
        echo "Invalid ID or transaction not found."
    fi
}

# FEATURE 4: Edit a transaction
edit_transaction() {
    local id type category amount description

    echo
    echo "===== EDIT TRANSACTION ====="

    read -r -p "Transaction ID to edit: " id

    if ! transaction_exists "$id"; then
        echo "Transaction not found."
        return 1
    fi

    read -r -p "New type (income/expense): " type
    read -r -p "New category: " category
    read -r -p "New amount (whole INR): " amount
    read -r -p "New description: " description

    if update_transaction_record \
        "$id" "$type" "$category" \
        "$amount" "$description"; then

        echo "Transaction updated successfully."
    else
        echo "Invalid details. No changes made."
    fi
}

# FEATURE 5: Calculate balance
check_balance() {
    echo
    echo "===== FINANCIAL BALANCE ====="

    awk -F, '
        NR > 1 {
            if ($3 == "income")
                income += $5

            else if ($3 == "expense")
                expense += $5
        }

        END {
            balance = income - expense

            printf "Total Income:   INR %.0f\n", income
            printf "Total Expenses: INR %.0f\n", expense
            printf "Current Balance: INR %.0f\n", balance
        }
    ' "$TRANSACTIONS_FILE"
}

