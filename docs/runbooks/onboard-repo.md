# Onboard a New Repository

Prepare a new repository for settings governance.

## Automatic Discovery

New repos are discovered automatically by the weekly sync. The
workflow creates a GitHub Issue with the `new-repo` label listing
repos created in the last 7 days.

## What the Sync Handles Automatically

- Repository settings (merge strategy, features, auto-merge)
- Security settings (secret scanning, push protection, vulnerability
  alerts)
- Branch protection rules
- Standard labels

## What Needs Manual Setup

The sync reports missing files but does not create them, since their
content is repo-specific:

1. `LICENSE` — choose the appropriate license
2. `README.md` — write project overview
3. `.gitignore` — configure for the project's languages
4. `CODEOWNERS` — assign default reviewers
5. `CONTRIBUTING.md` — contribution guidelines
6. `SECURITY.md` — vulnerability disclosure policy
7. `.pre-commit-config.yaml` — configure hooks for the project's stack
8. `.github/dependabot.yml` — configure dependency updates

## Adding Status Check Overrides

Each repo has different CI jobs. Add the required status check names
to `config/overrides.json`:

```json
{
  "repos": {
    "new-repo-name": {
      "branch_protection": {
        "required_status_checks": {
          "contexts": ["Build", "Test", "Lint"]
        }
      }
    }
  }
}
```

## Adding Description and Topics

The sync flags repos without a description or topics. Set them via:

```bash
gh repo edit gamaware/new-repo-name \
  --description "Short description" \
  --add-topic topic1 --add-topic topic2
```
