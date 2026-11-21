#!/usr/bin/env bash

STORAGE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$STORAGE_DIR")"
DATA_DIR="${DATA_DIR:-$PROJECT_DIR/data}"

TRANSACTIONS_FILE="$DATA_DIR/transactions.csv"
BUDGETS_FILE="$DATA_DIR/budgets.csv"
BACKUP_DIR="$PROJECT_DIR/backups"
ID_FILE="$DATA_DIR/.next_id"

initialize_storage() {
    mkdir -p "$DATA_DIR" "$BACKUP_DIR" || return 1
    chmod 700 "$DATA_DIR" "$BACKUP_DIR"

    if [[ ! -f "$TRANSACTIONS_FILE" ]]; then
        printf 'id,date,type,category,amount,description\n' > "$TRANSACTIONS_FILE"
    fi

    if [[ ! -f "$BUDGETS_FILE" ]]; then
        printf 'month,category,limit\n' > "$BUDGETS_FILE"
    fi

    if [[ ! -f "$ID_FILE" ]]; then
        awk -F',' '
            NR > 1 && $1 ~ /^[0-9]+$/ && $1 > max {
                max = $1
            }
            END {
                printf "%.0f\n", max + 1
            }
        ' "$TRANSACTIONS_FILE" > "$ID_FILE"
    fi

    chmod 600 "$TRANSACTIONS_FILE" "$BUDGETS_FILE" "$ID_FILE"
}

validate_amount() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]] || return 1
    awk -v a="$1" 'BEGIN { exit !(a > 0) }'
}

validate_date() {
    local input="$1"

    [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1

    awk -v d="$input" '
        BEGIN {
            split(d, a, "-")
            y = a[1] + 0
            m = a[2] + 0
            day = a[3] + 0

            if (y < 1 || m < 1 || m > 12)
                exit 1

            days[1]=31
            days[2]=28
            days[3]=31
            days[4]=30
            days[5]=31
            days[6]=30
            days[7]=31
            days[8]=31
            days[9]=30
            days[10]=31
            days[11]=30
            days[12]=31

            if (y % 400 == 0 ||
                (y % 4 == 0 && y % 100 != 0))
                days[2]=29

            if (day < 1 || day > days[m])
                exit 1
        }
    '
}

validate_text() {
    [[ -n "$1" &&
       "$1" != *","* &&
       "$1" != *$'\n'* &&
       "$1" != *$'\r'* ]]
}

validate_category() {
    validate_text "$1"
}

validate_month() {
    [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]
}

generate_id() {
    local id

    read -r id < "$ID_FILE" || return 1
    [[ "$id" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "$id"
}

transaction_exists() {
    local id="$1"

    [[ "$id" =~ ^[0-9]+$ ]] || return 1

    awk -F',' -v id="$id" '
        NR > 1 && $1 == id {
            found = 1
            exit
        }
        END {
            if (!found) exit 1
        }
    ' "$TRANSACTIONS_FILE"
}


save_transaction() {
    local date_value type category amount description id

    if [[ $# -eq 4 ]]; then
        date_value=$(date +%F)
        type="$1"
        category="$2"
        amount="$3"
        description="$4"
    elif [[ $# -eq 5 ]]; then
        date_value="$1"
        type="$2"
        category="$3"
        amount="$4"
        description="$5"
    else
        return 1
    fi

    validate_date "$date_value" || return 1
    [[ "$type" == "income" || "$type" == "expense" ]] || return 1
    validate_category "$category" || return 1
    [[ "$amount" =~ ^[0-9]+$ ]] || return 1
    validate_amount "$amount" || return 1
    validate_text "$description" || return 1

    id=$(generate_id) || return 1

    printf '%s,%s,%s,%s,%s,%s\n' \
        "$id" "$date_value" "$type" "$category" \
        "$amount" "$description" >> "$TRANSACTIONS_FILE" || return 1

    printf '%s\n' "$((10#$id + 1))" > "$ID_FILE" || return 1

    LAST_TRANSACTION_ID="$id"

    return 0
}


get_transactions() {
    cat "$TRANSACTIONS_FILE"
}

update_transaction() {
    local id="$1"
    local date_value="$2"
    local type="$3"
    local category="$4"
    local amount="$5"
    local description="$6"
    local temp

    transaction_exists "$id" || return 1
    validate_date "$date_value" || return 1
    [[ "$type" == "income" || "$type" == "expense" ]] || return 1
    validate_category "$category" || return 1
    validate_amount "$amount" || return 1
    validate_text "$description" || return 1

    temp=$(mktemp "$DATA_DIR/.transactions.XXXXXX") || return 1

    if awk -F',' -v OFS=',' \
        -v id="$id" \
        -v d="$date_value" \
        -v t="$type" \
        -v c="$category" \
        -v a="$amount" \
        -v desc="$description" '
        NR > 1 && $1 == id {
            $2=d
            $3=t
            $4=c
            $5=a
            $6=desc
        }
        { print }
    ' "$TRANSACTIONS_FILE" > "$temp"; then
        chmod 600 "$temp"
        if mv -f -- "$temp" "$TRANSACTIONS_FILE"; then
            echo "Transaction #$id updated."
        else
            rm -f -- "$temp"
            return 1
        fi
    else
        rm -f -- "$temp"
        return 1
    fi
}

update_transaction_record() {
    local id="$1"
    local date_value

    if [[ $# -eq 5 ]]; then
        transaction_exists "$id" || return 1

        date_value=$(awk -F',' -v id="$id" '
            NR > 1 && $1 == id {
                print $2
                exit
            }
        ' "$TRANSACTIONS_FILE")

        update_transaction "$id" "$date_value" \
            "$2" "$3" "$4" "$5"

    elif [[ $# -eq 6 ]]; then
        update_transaction "$@"
    else
        return 1
    fi
}

delete_transaction_record() {
    local id="$1"
    local temp

    transaction_exists "$id" || return 1

    temp=$(mktemp "$DATA_DIR/.transactions.XXXXXX") || return 1

    if awk -F',' -v id="$id" '
        NR == 1 || $1 != id
    ' "$TRANSACTIONS_FILE" > "$temp"; then
        chmod 600 "$temp"
        if mv -f -- "$temp" "$TRANSACTIONS_FILE"; then
            echo "Transaction #$id deleted."
        else
            rm -f -- "$temp"
            return 1
        fi
    else
        rm -f -- "$temp"
        return 1
    fi
}

backup_data() {
    local timestamp destination

    timestamp=$(date +%Y%m%d_%H%M%S)

    destination=$(mktemp -d \
        "$BACKUP_DIR/backup_${timestamp}_XXXXXX") || return 1

    chmod 700 "$destination"

    if ! cp -- "$TRANSACTIONS_FILE" "$BUDGETS_FILE" \
        "$ID_FILE" "$destination/"; then
        rm -rf -- "$destination"
        return 1
    fi

    echo "Backup created: $destination"
}

restore_data() {
    local source_dir="$1"
    local file staging

    for file in transactions.csv budgets.csv .next_id; do
        [[ -f "$source_dir/$file" ]] || return 1
    done

    staging=$(mktemp -d "$DATA_DIR/.restore.XXXXXX") || return 1

    if ! cp -- "$source_dir/transactions.csv" \
        "$source_dir/budgets.csv" \
        "$source_dir/.next_id" "$staging/"; then
        rm -rf -- "$staging"
        return 1
    fi

    if ! backup_data; then
        rm -rf -- "$staging"
        return 1
    fi

    for file in transactions.csv budgets.csv .next_id; do
        if ! cp -- "$staging/$file" "$DATA_DIR/$file"; then
            rm -rf -- "$staging"
            return 1
        fi
        chmod 600 "$DATA_DIR/$file"
    done

    rm -rf -- "$staging"

    echo "Data restored successfully!"
}
