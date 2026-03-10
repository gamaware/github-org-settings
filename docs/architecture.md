# Architecture Overview

## System Context

This repository is the single source of truth for GitHub repository
settings across all `gamaware` repositories. It acts as a control
plane that reads a desired state from JSON configuration and
reconciles it against the actual state via the GitHub API.

```text
+---------------------+       +------------------+
| config/             |       | GitHub API       |
| baseline.json       |------>| (repos, branches,|
| overrides.json      |       |  labels, security|
+---------------------+       +------------------+
         |                            ^
         v                            |
+---------------------+               |
| scripts/            |               |
| sync-repo-settings  |---------------+
| generate-report     |
+---------------------+
         |
         v
+---------------------+
| GitHub Issues       |
| Job Summaries       |
| Artifacts (90 days) |
+---------------------+
```

## Components

### Configuration Layer (`config/`)

- `baseline.json` — settings enforced on every repository
- `overrides.json` — per-repo exceptions (status checks, exclusions)

The effective configuration for a repo is the baseline deep-merged
with its overrides. If no override exists, the baseline is used
as-is.

### Sync Engine (`scripts/`)

`sync-repo-settings.sh` is the core reconciliation loop:

1. **Discovery** — `gh repo list` finds all non-archived repos
2. **Comparison** — for each repo, current state is fetched via API
   and compared field-by-field against the effective config
3. **Remediation** — in `--apply` mode, PATCH/PUT calls correct drift
4. **Reporting** — a markdown report is generated with per-repo diffs

The script handles 7 categories independently:

| Category | API Endpoint | Method |
| --- | --- | --- |
| Repo settings | `repos/{owner}/{repo}` | PATCH |
| Security | `repos/{owner}/{repo}` | PATCH |
| Vulnerability alerts | `repos/{owner}/{repo}/vulnerability-alerts` | PUT |
| Branch protection | `repos/{owner}/{repo}/branches/main/protection` | PUT |
| Labels | `repos/{owner}/{repo}/labels` | POST |
| Default branch | `repos/{owner}/{repo}` | PATCH |
| Metadata | (advisory only) | — |

### Composite Actions (`.github/actions/`)

Reusable building blocks consumed by workflows:

- `security-scan/` — Semgrep SAST + Trivy SCA with SARIF upload
- `sync-settings/` — wraps the sync script with structured outputs
- `update-pre-commit-composite/` — autoupdates hooks and creates PR

### Workflows (`.github/workflows/`)

| Workflow | Schedule | Purpose |
| --- | --- | --- |
| `sync-settings.yml` | Weekly Sunday 00:00 UTC | Settings enforcement |
| `quality-checks.yml` | PR + push | Linting and validation |
| `security.yml` | PR + push | SAST + SCA |
| `update-pre-commit-hooks.yml` | Weekly Sunday 00:00 UTC | Hook version updates |

### Reporting

Drift is communicated through three channels:

1. **GitHub Issues** — auto-created with `settings-drift` label when
   drift is found, auto-closed when all repos are compliant
2. **Job Summaries** — visible in the Actions run page
3. **Artifacts** — full markdown report stored for 90 days

## Security Model

- The `ORG_SETTINGS_PAT` secret provides API access with `repo` and
  `admin:org` scopes
- Workflows use least-privilege `permissions` blocks
- All third-party actions are pinned to SHA commits
- Secret scanning and push protection are enforced on this repo too

## Design Decisions

Detailed rationale is documented in Architecture Decision Records:

- [ADR 001: Settings Governance](adr/001-settings-governance.md)
- [ADR 002: Sync Architecture](adr/002-sync-architecture.md)
