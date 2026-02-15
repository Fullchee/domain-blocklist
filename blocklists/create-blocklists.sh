#!/bin/zsh

update_keiyoushi_domains() {
	rm -f ~/.dotfiles/post-install/blocklists/keiyoushi-domains.txt
	curl -s https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json \
	| jq -r '[.[].sources[].baseUrl]
			| map(split(",")[])                               # split comma-separated URLs
			| map(gsub("(^\\s+|\\s+$)"; ""))                  # trim whitespace
			| map(gsub("^https://"; ""))                      # remove https:// prefix
			| map(gsub("^http://"; ""))                       # remove http:// prefix (optional safety)
			| map(gsub("^www\\."; ""))                        # remove www.
			| map(gsub("#$"; ""))                             # remove trailing #
			| unique
			| .[]' > ~/.dotfiles/post-install/blocklists/keiyoushi-domains.txt
}
update_keiyoushi_domains

combine_domains() {
    filename=~/.dotfiles/post-install/blocklists/combined_domains.txt
    rm -f $filename
    cat $(ls ~/.dotfiles/post-install/blocklists/*.txt | grep -v 'combined_domains.txt') | sort -u > $filename
}
combine_domains


(
cat <<'EOF'
127.0.0.1   localhost
255.255.255.255 broadcasthost
::1             localhost

# Custom blocklist below
EOF

awk '{print "0.0.0.0", $0}' combined_domains.txt
) | sudo tee /etc/hosts.new > /dev/null
