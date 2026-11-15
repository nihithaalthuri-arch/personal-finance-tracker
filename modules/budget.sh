#!/bin/bash
# Person 2: Monthly category budgets.
calculate_spending() {
    local month="$1" category="$2"
    awk -F, -v m="$month" -v c="$category" '
        NR > 1 && substr($2,1,7)==m && $3=="expense" && $4==c {total+=$5}
        END {printf "%.0f\n",total}' "$TRANSACTIONS_FILE"
}

set_budget() {
    local month category limit
    read -r -p 'Month (YYYY-MM): ' month
    read -r -p 'Category: ' category
    read -r -p 'Budget limit (whole INR): ' limit
    if save_budget_record "$month" "$category" "$limit"; then
        echo 'Budget saved (previous limit for this month/category replaced).'
    else
        echo 'Invalid month, category or amount.'
    fi
}

view_budgets() {
    local month category limit spent remaining percent
    printf '\n%-9s %-15s %-9s %-9s %-10s %s\n' Month Category Limit Spent Remaining Status
    while IFS=, read -r month category limit; do
        [ "$month" = month ] && continue
        spent="$(calculate_spending "$month" "$category")"
        remaining=$((limit - spent))
        percent=$((spent * 100 / limit))
        if [ "$spent" -gt "$limit" ]; then
            status='OVER BUDGET'
        elif [ "$percent" -ge 80 ]; then
            status='80%+ USED'
        else
            status='OK'
        fi
        printf '%-9s %-15s %-9s %-9s %-10s %s\n' "$month" "$category" "$limit" "$spent" "$remaining" "$status"
    done < "$BUDGETS_FILE"
}

check_budget() {
    local month category found
    read -r -p 'Month (YYYY-MM): ' month
    read -r -p 'Category: ' category
    if ! validate_month "$month" || ! validate_text "$category"; then
        echo 'Invalid month/category.'; return
    fi
    found="$(awk -F, -v m="$month" -v c="$category" 'NR>1 && $1==m && $2==c {print $3; exit}' "$BUDGETS_FILE")"
    if [ -z "$found" ]; then echo 'No budget found.'; return; fi
    local spent
    spent="$(calculate_spending "$month" "$category")"
    printf 'Limit: INR %s | Spent: INR %s | Remaining: INR %s\n' "$found" "$spent" "$((found-spent))"
}
