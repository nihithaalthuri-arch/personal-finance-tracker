#!/bin/bash

# Person 3: Summaries and category charts.

# Validate month format (YYYY-MM)
validate_month() {
    [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]
}

monthly_report() {
    local month="$1"
    if ! validate_month "$month"; then echo 'Enter a valid month (YYYY-MM).'; return 1; fi
    printf '\n===== REPORT FOR %s =====\n' "$month"
   echo "Transactions for $month:"
   grep "^.*,${month}-" "$TRANSACTIONS_FILE" |
   sed 's/,/ | /g'
   awk -F, -v m="$month" '
        NR>1 && substr($2,1,7)==m {
            if ($3=="income") income+=$5
            else if ($3=="expense") expenses+=$5
        }
        END {printf "Income: INR %.0f\nExpenses: INR %.0f\nNet savings: INR %.0f\n", income, expenses, income-expenses}' "$TRANSACTIONS_FILE"
    echo 'Expenses by category (each # represents about INR 500):'
    awk -F, -v m="$month" '
        NR>1 && substr($2,1,7)==m && $3=="expense" {sum[$4]+=$5}
        END {for (c in sum) printf "%s,%d\n",c,sum[c]}' "$TRANSACTIONS_FILE" |
    sort -t, -k2,2nr |
    while IFS=, read -r category amount; do
        local bars i chart
        bars=$(((amount + 499) / 500))
        [ "$bars" -gt 30 ] && bars=30
        chart=''
        i=0
        while [ "$i" -lt "$bars" ]; do chart="${chart}#"; i=$((i + 1)); done
        printf '%-16s %-30s INR %s\n' "$category" "$chart" "$amount"
    done
    echo
    echo "Top Spending Category:"

    awk -F, -v m="$month" '
    NR > 1 && substr($2,1,7)==m && $3=="expense" {
        category[$4] += $5
       }

    END {
        for (c in category) {
            if (category[c] > max) {
                max = category[c]
                highest = c
            }
        }

        if (highest == "")
            print "No expenses recorded."
        else {
            print "Category:", highest
            print "Amount: INR", max
           }
      }
' "$TRANSACTIONS_FILE"
}

report_menu() {
    local month
    read -r -p 'Enter month (YYYY-MM): ' month
    monthly_report "$month"
}

export_monthly_report() {
    local month destination

    read -r -p 'Month (YYYY-MM): ' month

    if ! validate_month "$month"; then
        echo "Invalid month."
        return 1
    fi

    mkdir -p "$DATA_DIR"

   destination="$DATA_DIR/report_${month}.txt"

    if monthly_report "$month" > "$destination"; then
        echo "Report saved to $destination"
    else
        echo "Failed to save report."
        return 1
    fi
}

# Compatibility with main.sh
export_report() {
    export_monthly_report
}
