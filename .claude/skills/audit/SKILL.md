---
name: audit
description: Run a dry-run settings audit across all repositories
user-invocable: true
disable-model-invocation: true
---

# Audit Repository Settings

Run a dry-run sync to check for drift without applying changes.

## Steps

1. Run the sync script in dry-run mode:

```bash
./scripts/sync-repo-settings.sh --dry-run
```

2. Display the report:

```bash
cat reports/sync-report.md
```
