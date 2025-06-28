#!/bin/bash

LOG_BASE="/var/www/vhosts"
HIT_THRESHOLD=100
DAYS_AGO="${1:-0}"
DOMAIN_FILTER="$2"
SORT_OPTION="$3"

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

        	function extract_bot_name(ua, botname, boturl, match_arr) {
        	    ua_lc = tolower(ua)
        
        	    if (ua_lc ~ /bot/) {
        	        # Try to extract the bot name
        	        if (match(ua, /([A-Za-z0-9._\-]+bot)/, match_arr)) {
        	            botname = match_arr[1]
        	        } else {
        	            botname = "UnknownBot"
        	        }
        
        	        # Try to extract the first URL
        	        if (match(ua, /\+?https?:\/\/[^ )"]+/, match_arr)) {
        	            boturl = match_arr[0]
        	        } else {
        	            boturl = ""
        	        }
        	
        	        return botname (boturl ? " (" boturl ")" : "")
        	    }
        
        	    # Not a bot, but has a URL
        	    if (match(ua, /\+?https?:\/\/[^ )"]+/, match_arr)) {
        	        return match_arr[0]
        	    }
        	
        	    # Else return the whole user-agent string
        	    return ua
        	}


            {
                ip = $1
                ua = ""
                n = split($0, parts, "\"")
                if (length(parts) >= 6) {
                    ua = parts[6]
                }

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

                    if (!(key in bots)) {
                        bots[key] = extract_bot_name(ua)
                    }
                }
            }

            END {
                for (k in counts)
                    if (counts[k] > '"$HIT_THRESHOLD"') {
                        botstring = (k in bots) ? bots[k] : "-"
                        print sortkeys[k] "\t" k "\t" counts[k] "\t" botstring
                    }
            }
        ' "$log_file" >> "$TMP_OUTPUT"
    done
done

# Header
echo -e "Domain\t\tDate\t\tIP\t\tHits\tBot/User-Agent"
echo "---------------------------------------------------------------------------------------"

# Sort and output
case "$SORT_OPTION" in
    --sort=ip)
        sort -k4,4 "$TMP_OUTPUT" | cut -f2-
        ;;
    --sort=hits)
        sort -k4,4nr "$TMP_OUTPUT" | cut -f2-
        ;;
    *)  # default: sort by date
        sort -k1,1 "$TMP_OUTPUT" | cut -f2-
        ;;
esac

rm -f "$TMP_OUTPUT"
