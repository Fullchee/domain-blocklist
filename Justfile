all: update-keiyoushi combine update-hosts

setup:
    brew install curl
    brew install jq
    brew install prek
    prek install

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

combine:
    @echo "Combining all blocklists → blocklists/combined_domains.txt"
    mkdir -p blocklists
    rm -f blocklists/combined_domains.txt
    for f in blocklists/*.txt; do \
        if [ "$(basename "$f")" != "combined_domains.txt" ]; then \
            cat "$f"; \
        fi; \
    done | sort -u | sed '/./,$!d' > blocklists/combined_domains.txt
    @echo "Combined all blocklists → blocklists/combined_domains.txt ✅"

update-hosts: update-repo-hosts-file update-mac-hosts-file

update-repo-hosts-file:
    @echo "Generating blocklists/hosts from blocklists/combined_domains.txt"
    mkdir -p blocklists
    if [ ! -s blocklists/combined_domains.txt ]; then \
        echo "blocklists/combined_domains.txt is missing or empty — run 'just combine' first"; exit 1; \
    fi
    awk '{print "0.0.0.0", $0}' blocklists/combined_domains.txt > blocklists/hosts
    sudo cp blocklists/hosts /etc/hosts
    @echo "Wrote blocklists/hosts ✅"


update-mac-hosts-file:
    @echo "Generating blocklists/hosts with system defaults..."
    @# 1. Create a temporary hosts file with defaults
    echo "127.0.0.1       localhost" > blocklists/hosts.tmp
    echo "255.255.255.255 broadcasthost" >> blocklists/hosts.tmp
    echo "::1             localhost" >> blocklists/hosts.tmp
    echo "" >> blocklists/hosts.tmp

    @# 2. Append the blocklist domains
    awk '{print "0.0.0.0", $0}' blocklists/combined_domains.txt >> blocklists/hosts.tmp

    @# 3. Move to system (with backup)
    sudo rm -f /etc/hosts.bak
    sudo cp /etc/hosts /etc/hosts.bak
    sudo mv blocklists/hosts.tmp /etc/hosts
    @echo "Updated /etc/hosts and created backup at /etc/hosts.bak ✅"
