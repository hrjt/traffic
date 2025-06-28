#!/bin/bash

LOG_BASE="/var/www/vhosts"
HIT_THRESHOLD=5
DAYS_AGO="${1:-0}"
DOMAIN_FILTER="$2"
SORT_OPTION="$3"

echo "Traffic Analysis Script v.1.0 by HarjeetSingh@yahoo.com"
echo "-------------------------------------------------------"
echo "Usage: $0 [days] [domain_filter] [sort_option]"
echo "days: number of days to look back (i.e. 15)"
echo "domain_filter: specific domain to filter logs (optional)"
echo "sort_option: sorting preference (default: by date, options: --sort=ip, --sort=hits)"

echo "Processing logs from $LOG_BASE for the last $DAYS_AGO days..."

# Calculate cutoff as epoch
if [[ "$DAYS_AGO" -gt 0 ]]; then
    CUTOFF_DATE=$(date -d "$DAYS_AGO days ago" +"%s")
else
    CUTOFF_DATE=0
fi

TMP_OUTPUT=$(mktemp)

for domain_path in "$LOG_BASE"/*; do
    domain=$(basename "$domain_path")

    if [[ -n "$DOMAIN_FILTER" && "$domain" != "$DOMAIN_FILTER" ]]; then
        continue
    fi

    access_logs=("$domain_path/logs/access_log.processed" "$domain_path/logs/proxy_access_log")

    for log_file in "${access_logs[@]}"; do
        [[ -f "$log_file" ]] || continue

        awk -v domain="$domain" -v cutoff="$CUTOFF_DATE" '
            function parse_date(str,   months, d, m, y, day, mon, yr, sortable, epoch) {
                split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", months, " ")
                if (match(str, /\[([0-9]{2})\/([A-Za-z]{3})\/([0-9]{4})/, d)) {
                    day = d[1]; mon = d[2]; yr = d[3]
                    for (i = 1; i <= 12; i++) if (months[i] == mon) m = i
                    epoch = mktime(yr " " m " " day " 00 00 00")
                    sortable = sprintf("%04d%02d%02d", yr, m, day)
                    return epoch "|" sortable "|" day "/" mon "/" yr
                }
                return ""
            }

            {
                ip = $1
                result = parse_date($0)
                if (result == "") next

                split(result, parts, "|")
                epoch = parts[1]
                sortkey = parts[2]
                display_date = parts[3]

                if (epoch >= cutoff) {
                    key = domain "\t" display_date "\t" ip
                    counts[key]++
                    sortkeys[key] = sortkey
                }
            }

            END {
                for (k in counts)
                    if (counts[k] > '"$HIT_THRESHOLD"')
                        print sortkeys[k] "\t" k "\t" counts[k]
            }
        ' "$log_file" >> "$TMP_OUTPUT"
    done
done

# Header
echo -e "Domain\t\tDate\t\tIP\t\tHits"
echo "-----------------------------------------------------------"

# Sort and strip hidden sort key
case "$SORT_OPTION" in
    --sort=ip)
        sort -k4,4 "$TMP_OUTPUT" | cut -f2-
        ;;
    --sort=hits)
        sort -k5,5nr "$TMP_OUTPUT" | cut -f2-
        ;;
    *)  # default: sort by sortable date (field 1)
        sort -k1,1 "$TMP_OUTPUT" | cut -f2-
        ;;
esac

rm -f "$TMP_OUTPUT"
