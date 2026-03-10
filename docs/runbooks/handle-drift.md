# Handle Drift Detection

Respond to a `settings-drift` issue created by the sync workflow.

## Triage

1. Open the linked workflow run from the issue body
2. Review the Job Summary to see which repos drifted and what changed
3. Download the report artifact for full details

## Common Causes

| Cause | Action |
| --- | --- |
| Manual settings change via GitHub UI | Let the next `--apply` run fix it |
| New repo created without governance | The sync will apply baseline settings |
| Legitimate exception needed | Add an override in `config/overrides.json` |
| PAT expired or lacks scopes | Rotate the `ORG_SETTINGS_PAT` secret |

## Manual Fix

If you need to fix drift immediately without waiting for the
weekly run:

```bash
gh workflow run sync-settings.yml -f mode="--apply"
```

Or locally:

```bash
./scripts/sync-repo-settings.sh --apply
```

## Issue Lifecycle

- The workflow auto-creates a new issue each time drift is found
- Previous drift issues are auto-closed with a superseded comment
- When all repos are compliant, open drift issues are auto-closed
  with a compliant comment
