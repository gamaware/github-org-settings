# ADR 001: Settings Governance Approach

## Status

Accepted

## Context

Multiple repositories under the `gamaware` GitHub account need
consistent settings (merge strategies, branch protection, security
scanning). Manual configuration is error-prone and does not scale as
new repositories are created.

## Decision

Create a dedicated repository (`github-org-settings`) that:

1. Defines a baseline configuration in JSON (`config/baseline.json`)
2. Allows per-repo overrides (`config/overrides.json`) for settings
   that legitimately differ (e.g., required status check names)
3. Uses a shell script to compare current settings against the
   baseline via the GitHub API
4. Runs weekly via GitHub Actions to detect and correct drift
5. Sends email reports summarizing changes

## Consequences

- All repositories converge to a single standard
- New repositories are automatically discovered and configured
- Per-repo exceptions are explicit and version-controlled
- Requires a Personal Access Token (PAT) with `repo` and `admin:org`
  scopes stored as a repository secret
- Settings changes go through PR review like any code change
