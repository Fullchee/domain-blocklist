# Domain blocklists

## Setup

1. Install `just`
   1. `brew install just`
2. Install `prek`
   1. `brew install prek`
3. Enable pre-commit hooks (prek)
   1. `prek install` — repository-local hook runs `just` when files under `blocklists/` change (hook id: `just-blocklists`). To skip the hook for a commit: `SKIP=just-blocklists git commit -m "..."` or `git commit --no-verify`.

## Files


```mermaid
flowchart TD
  Internet([Internet])

  subgraph blocklists["blocklists/"]
    FB["fullchee-blocklist.txt"]
    KD["keiyoushi-domains.txt"]
    CD["combined-domains.txt"]
    LB["leechblock.txt"]
    HS["hosts"]
  end

  Internet --> KD
  FB --> CD
  KD --> CD
  CD -->|update-leechblock| LB
  CD -->|update-repo-hosts-file| HS
  HS -->|copied to| ETC["/etc/hosts (system)"]
```
