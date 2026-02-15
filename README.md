# Domain blocklists

## Setup

1. Install `just`
   1. `brew install just`
2. Install `prek`
   1. `brew install prek`
3. Enable pre-commit hooks (prek)
   1. `prek install` — repository-local hook runs `just` when files under `blocklists/` change (hook id: `just-blocklists`). To skip the hook for a commit: `SKIP=just-blocklists git commit -m "..."` or `git commit --no-verify`.

## Blocklists

1. keiyoushi-domains.txt
  - Used a script to get domains from https://github.com/keiyoushi/extensions-source
2. My manual domain list: `manual-manga-blocklist.txt`
3. Then I combine them with a script
