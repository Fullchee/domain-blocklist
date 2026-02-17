all: ci update-local-etc-hosts-file

ci: format-fullchee update-keiyoushi update-games combine update-leechblock update-repo-hosts-file

setup:
    brew install curl
    brew install jq
    brew install prek
    uv sync
    prek install

format-fullchee:
    uv run python -c "import tldextract; [print(f'{e.subdomain + \".\" if e.subdomain and e.subdomain != \"www\" else \"\"}{e.domain}.{e.suffix}'.replace('www.', '')) for line in open('blocklists/fullchee-blocklist.txt') for e in [tldextract.extract(line.strip())] if e.domain]" \
    | sort -u \
    | sed '/^$/d' > blocklists/fullchee-blocklist.txt.tmp

    mv blocklists/fullchee-blocklist.txt.tmp blocklists/fullchee-blocklist.txt
    @echo "blocklists/fullchee-blocklist.txt is now sorted, unique, and TLD-only. ✅"

update-keiyoushi:
    @echo "Fetching keiyoushi domains → blocklists/keiyoushi-domains.txt"
    mkdir -p blocklists
    curl -sf https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json \
        | jq -r '[.[].sources[].baseUrl] \
            | map(split(",")[]) \
            | map(gsub("(^\\s+|\\s+$)"; "")) \
            | map(gsub("^https://"; "")) \
            | map(gsub("^http://"; "")) \
            | map(gsub("^www\\."; "")) \
            | map(gsub("#$"; "")) \
            | unique \
            | .[]' \
        | grep -v "^127\.0\.0\.1" > blocklists/keiyoushi-domains.txt
    @echo "Updated keiyoushi-domains.txt! ✅"

update-games:
    @echo "Fetching AdGuard GameList → blocklists/games.txt"
    mkdir -p blocklists
    curl -sfL https://raw.githubusercontent.com/Mafraysse/AdGuard_GameList-Filter/refs/heads/main/Listing_raw.txt \
        | sed 's/\r$//' \
        | sed -E 's/^\s*#.*$//; /^\s*$/d' \
        | sed -E 's/^\|\|?//; s/^\*\.//; s#^https?://##; s#/.*##; s/\^.*$//; s/\:.*$//; s/^\s*www\.//;' \
        | grep -E '^[A-Za-z0-9._-]+\.[A-Za-z]{2,}' \
        | sort -u > blocklists/games.txt
    @echo "Updated blocklists/games.txt! ✅"



combine:
    @echo "Combining selected blocklists → blocklists/combined-domains.txt"
    mkdir -p blocklists
    rm -f blocklists/combined-domains.txt
    cat blocklists/fullchee-blocklist.txt blocklists/keiyoushi-domains.txt blocklists/games.txt \
        | sort -u | sed '/./,$!d' > blocklists/combined-domains.txt
    @echo "Combined selected blocklists → blocklists/combined-domains.txt ✅"

update-leechblock:
    @echo "Generating blocklists/leechblock.txt (sites1=) from blocklists/combined-domains.txt"
    mkdir -p blocklists
    if [ ! -s blocklists/combined-domains.txt ]; then \
        echo "blocklists/combined-domains.txt is missing or empty — run 'just combine' first"; exit 1; \
    fi
    if [ ! -f blocklists/leechblock.txt ]; then \
        echo "blocklists/leechblock.txt not found — creating a template"; \
        printf 'setName1=\nsites1=\n' > blocklists/leechblock.txt; \
    fi

    # Build a single space-separated domain string from combined-domains.txt and replace the first `sites1=` (prefer line 2)
    awk 'NR==FNR{ if($0!=""){ if(d=="") d=$0; else d=d " " $0 } next } { if (FNR==2 && /^sites1=/){ print "sites1=" d; next } if (/^sites1=/ && !repl){ print "sites1=" d; repl=1; next } print }' blocklists/combined-domains.txt blocklists/leechblock.txt > blocklists/leechblock.txt.tmp && mv blocklists/leechblock.txt.tmp blocklists/leechblock.txt
    @echo "Updated blocklists/leechblock.txt ✅"

update-repo-hosts-file:
    @echo "Generating blocklists/hosts from blocklists/combined-domains.txt"
    mkdir -p blocklists
    if [ ! -s blocklists/combined-domains.txt ]; then \
        echo "blocklists/combined-domains.txt is missing or empty — run 'just combine' first"; exit 1; \
    fi
    awk '{print "0.0.0.0", $0}' blocklists/combined-domains.txt > blocklists/hosts
    @echo "Updated blocklists/hosts ✅"

update-local-etc-hosts-file:
    @echo "Generating blocklists/hosts with system defaults..."
    @# 1. Create a temporary hosts file with defaults
    echo "127.0.0.1       localhost" > blocklists/hosts.tmp
    echo "255.255.255.255 broadcasthost" >> blocklists/hosts.tmp
    echo "::1             localhost" >> blocklists/hosts.tmp
    echo "" >> blocklists/hosts.tmp

    @# 2. Append the blocklist domains
    awk '{print "0.0.0.0", $0}' blocklists/combined-domains.txt >> blocklists/hosts.tmp

    @# 3. Move to system (with backup)
    sudo rm -f /etc/hosts.bak
    sudo cp /etc/hosts /etc/hosts.bak
    sudo mv blocklists/hosts.tmp /etc/hosts
    @echo "Updated /etc/hosts and created backup at /etc/hosts.bak ✅"
