#!/bin/bash
# Person 4: Storage and validation. Compatible with macOS Bash 3.2.
FINANCE_DATA_DIR="${FINANCE_DATA_DIR:-$PROJECT_ROOT/data}"
TRANSACTIONS_FILE="$FINANCE_DATA_DIR/transactions.csv"
BUDGETS_FILE="$FINANCE_DATA_DIR/budgets.csv"

initialize_storage() {
    umask 077
    mkdir -p "$FINANCE_DATA_DIR" || return 1
    if [ ! -f "$TRANSACTIONS_FILE" ]; then
        printf 'id,date,type,category,amount,description\n' > "$TRANSACTIONS_FILE"
    fi
    if [ ! -f "$BUDGETS_FILE" ]; then
        printf 'month,category,limit\n' > "$BUDGETS_FILE"
    fi
}

validate_amount() { [[ "$1" =~ ^[1-9][0-9]*$ ]]; }
validate_id() { [[ "$1" =~ ^[1-9][0-9]*$ ]]; }
validate_month() { [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]; }
validate_text() {
    [ -n "$1" ] || return 1
    case "$1" in
        *','*|*$'\n'*|*$'\r'*|[=+@-]*) return 1 ;;
    esac
    return 0
}

next_transaction_id() {
    awk -F, 'NR > 1 && $1 > max { max = $1 } END { print max + 1 }' "$TRANSACTIONS_FILE"
}

save_transaction() {
    local type="$1" category="$2" amount="$3" description="$4" id
    [[ "$type" == income || "$type" == expense ]] || return 1
    validate_text "$category" && validate_text "$description" && validate_amount "$amount" || return 1
    id="$(next_transaction_id)" || return 1
    printf '%s,%s,%s,%s,%s,%s\n' "$id" "$(date +%F)" "$type" "$category" "$amount" "$description" >> "$TRANSACTIONS_FILE" || return 1
    LAST_TRANSACTION_ID="$id"
}

get_transactions() { cat "$TRANSACTIONS_FILE"; }

transaction_exists() {
    validate_id "$1" || return 1
    awk -F, -v id="$1" 'NR > 1 && $1 == id { found = 1 } END { exit !found }' "$TRANSACTIONS_FILE"
}

delete_transaction_record() {
    local id="$1" tmp
    transaction_exists "$id" || return 1
    tmp="$(mktemp "$FINANCE_DATA_DIR/.transactions.XXXXXX")" || return 1
    if awk -F, -v id="$id" 'NR == 1 || $1 != id' "$TRANSACTIONS_FILE" > "$tmp"; then
        mv "$tmp" "$TRANSACTIONS_FILE"
    else
        rm -f "$tmp"; return 1
    fi
}

update_transaction_record() {
    local id="$1" type="$2" category="$3" amount="$4" description="$5" tmp
    transaction_exists "$id" || return 1
    [[ "$type" == income || "$type" == expense ]] || return 1
    validate_text "$category" && validate_amount "$amount" && validate_text "$description" || return 1
    tmp="$(mktemp "$FINANCE_DATA_DIR/.transactions.XXXXXX")" || return 1
    if awk -F, -v OFS=, -v id="$id" -v t="$type" -v c="$category" -v a="$amount" -v d="$description" '
        NR > 1 && $1 == id { $3=t; $4=c; $5=a; $6=d }
        { print }
    ' "$TRANSACTIONS_FILE" > "$tmp"; then
        mv "$tmp" "$TRANSACTIONS_FILE"
    else
        rm -f "$tmp"; return 1
    fi
}

save_budget_record() {
    local month="$1" category="$2" limit="$3" tmp
    validate_month "$month" && validate_text "$category" && validate_amount "$limit" || return 1
    tmp="$(mktemp "$FINANCE_DATA_DIR/.budgets.XXXXXX")" || return 1
    if awk -F, -v m="$month" -v c="$category" 'NR == 1 || !($1 == m && $2 == c)' "$BUDGETS_FILE" > "$tmp"; then
        printf '%s,%s,%s\n' "$month" "$category" "$limit" >> "$tmp"
        mv "$tmp" "$BUDGETS_FILE"
    else
        rm -f "$tmp"; return 1
    fi
}

backup_data() {
    local folder="$FINANCE_DATA_DIR/backups/$(date +%Y%m%d_%H%M%S)_$$"
    mkdir -p "$folder" || return 1
    cp "$TRANSACTIONS_FILE" "$BUDGETS_FILE" "$folder/" || return 1
    printf 'Backup saved to: %s\n' "$folder"
}
