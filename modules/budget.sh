#!/bin/bash
# ==========================================
#  BUDGET MANAGEMENT
# PERSONAL FINANCE TRACKER
# ==========================================
# FEATURE 1: Initialize budget storage
initialize_budgets() {
    mkdir -p "$(dirname "$BUDGETS_FILE")"
    if [ ! -f "$BUDGETS_FILE" ]; then
        echo "month,category,limit" > "$BUDGETS_FILE"
        echo "Budget file created successfully."
    fi
}
# FEATURE 2: Validate month format
validate_budget_month() {
    [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]
}
# FEATURE 3: Validate budget amount
validate_budget_amount() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}
# FEATURE 4: Set a monthly budget
set_budget() {
    local month category limit temp_file
    initialize_budgets
    echo
    echo "===== SET MONTHLY BUDGET ====="
    read -r -p "Enter month (YYYY-MM): " month
    read -r -p "Enter category: " category
    read -r -p "Enter budget limit (INR): " limit
    if ! validate_budget_month "$month"; then
        echo "Invalid month format."
        return 1
    fi
    if [ -z "$category" ] || [[ "$category" == *,* ]]; then
        echo "Invalid category."
        return 1
    fi
    if ! validate_budget_amount "$limit"; then
        echo "Enter a positive whole-number amount."
        return 1
    fi
    temp_file=$(mktemp "${BUDGETS_FILE}.XXXXXX") || return 1
    awk -F, -v OFS=, \
        -v m="$month" \
        -v c="$category" \
        -v l="$limit" '
        NR == 1 {
            print
            next
        }
        $1 == m && $2 == c {
            $3 = l
            found = 1
        }
        {
            print
        }
        END {
            if (!found)
                print m, c, l
        }
    ' "$BUDGETS_FILE" > "$temp_file"

    if [ $? -eq 0 ]; then
