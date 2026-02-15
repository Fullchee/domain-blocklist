# Justfile for domain-blocklist
# Tasks:
#   just          -> default: run `update-keiyoushi` then `combine`
#   just update-keiyoushi
#   just combine
#   just hosts     -> generate /etc/hosts.new (requires sudo)
#   just apply-hosts -> copy /etc/hosts.new -> /etc/hosts (requires sudo)
# Requires: curl, jq

all: update-keiyoushi combine update-hosts

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
            | .[]' > blocklists/keiyoushi-domains.txt
    @echo "Updated keiyoushi-domains.txt! ✅"


combine:
    @echo "Combining all blocklists → blocklists/combined_domains.txt"
    mkdir -p blocklists
    rm -f blocklists/combined_domains.txt
    for f in blocklists/*.txt; do \
        [ "$(basename "$f")" = "combined_domains.txt" ] && continue; \
        cat "$f"; \
    done | sort -u > blocklists/combined_domains.txt
    @echo "Combined all blocklists → blocklists/combined_domains.txt ✅"

update-hosts:
    @echo "Generating blocklists/hosts from blocklists/combined_domains.txt"
    mkdir -p blocklists
    if [ ! -s blocklists/combined_domains.txt ]; then \
        echo "blocklists/combined_domains.txt is missing or empty — run 'just combine' first"; exit 1; \
    fi
    awk '{print "0.0.0.0", $0}' blocklists/combined_domains.txt > blocklists/hosts
    @echo "Wrote blocklists/hosts ✅"
