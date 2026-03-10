# ADR 002: Sync Architecture

## Status

Accepted

## Context

The sync mechanism needs to handle three categories of settings:

1. Repository-level settings (merge strategies, features)
2. Security settings (secret scanning, push protection)
3. Branch protection rules (reviews, status checks, linear history)

Each category uses different GitHub API endpoints and has different
update semantics.

## Decision

Use a single shell script (`scripts/sync-repo-settings.sh`) that:

1. Discovers all non-archived repositories via `gh repo list`
2. For each repository, compares current state against the effective
   configuration (baseline merged with overrides)
3. Generates a markdown report with drift details
4. In `--apply` mode, patches settings via the GitHub API
5. Supports `--dry-run` mode for validation without changes

The script is invoked by a GitHub Actions workflow that:

- Runs on a weekly schedule (Sunday midnight UTC)
- Can be triggered manually with mode selection
- Uploads the report as an artifact
- Sends the report via email

## Consequences

- Shell script keeps the implementation simple and auditable
- `--dry-run` mode enables safe testing before applying
- Report artifacts provide an audit trail
- Email notifications ensure visibility without checking GitHub
- The PAT must have sufficient scopes for all three setting categories
