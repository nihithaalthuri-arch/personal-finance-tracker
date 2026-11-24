#!/usr/bin/env bash
# PERSON 2 - BUDGET MANAGEMENT
# Completed for integration: the supplied upload ended mid-function.

initialize_budgets() {
    mkdir -p "$(dirname "$BUDGETS_FILE")" || return 1
    if [ ! -f "$BUDGETS_FILE" ]; then
        printf 'month,category,limit\n' > "$BUDGETS_FILE"
        echo "Budget file created successfully."
    fi
}

validate_budget_month() {
    validate_month "$1"
}

validate_budget_amount() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]
}

set_budget() {
    local month category limit temp_file
    initialize_budgets || return 1

    echo
    echo "===== SET MONTHLY BUDGET ====="
    read -r -p "Enter month (YYYY-MM): " month
    read -r -p "Enter category: " category
    read -r -p "Enter budget limit (INR): " limit

    if ! validate_budget_month "$month"; then
        echo "Invalid month format."
        return 1
    fi
    if [ -z "$category" ] || [[ "$category" == *,* ]] ||
       [[ "$category" == *$'\n'* ]] || [[ "$category" == *$'\r'* ]]; then
        echo "Invalid category."
        return 1
    fi
    if ! validate_budget_amount "$limit"; then
        echo "Enter a positive whole-number amount."
        return 1
    fi

    temp_file=$(mktemp "${BUDGETS_FILE}.XXXXXX") || return 1
    if awk -F, -v OFS=, -v m="$month" -v c="$category" -v l="$limit" '
        NR == 1 { print; next }
        $1 == m && $2 == c { $3 = l; found = 1 }
        { print }
        END { if (!found) print m, c, l }
    ' "$BUDGETS_FILE" > "$temp_file"; then
        chmod 600 "$temp_file"
        if mv -f -- "$temp_file" "$BUDGETS_FILE"; then
            echo "Budget saved successfully."
        else
            rm -f -- "$temp_file"
            return 1
        fi
    else
        rm -f -- "$temp_file"
        echo "Could not save budget."
        return 1
    fi
}

view_budgets() {
    local month
    echo
    echo "===== VIEW MONTHLY BUDGETS ====="
    read -r -p "Enter month (YYYY-MM): " month
    if ! validate_budget_month "$month"; then
        echo "Invalid month format."
        return 1
    fi

    awk -F, -v m="$month" '
        BEGIN { found = 0 }
        NR > 1 && $1 == m {
            printf "%-18s INR %s\n", $2, $3
            found = 1
        }
        END {
            if (!found) print "No budgets found for this month."
        }
    ' "$BUDGETS_FILE"
}
