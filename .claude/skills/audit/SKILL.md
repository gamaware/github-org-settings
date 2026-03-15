---
name: audit
description: >-
  Run a dry-run settings audit across all repositories to detect drift
  from baseline. Use this skill whenever the user wants to check repo
  settings, find drift, audit governance, or says "are all repos in
  sync?" or "check settings across the org".
disable-model-invocation: true
user-invocable: true
---

# Audit Repository Settings

Run a dry-run sync to check for drift without applying changes.

## Steps

1. Run the sync script in dry-run mode:

```bash
./scripts/sync-repo-settings.sh --dry-run
```

1. Display the report:

```bash
cat reports/sync-report.md
```
