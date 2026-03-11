# GitHub Organization Settings — Project Instructions

## Repository Overview

Automated governance for GitHub repository settings across the
`gamaware` organization. Contains shell scripts, composite GitHub
Actions, and workflows that discover repos, compare settings against
a baseline, apply corrections, and report drift via GitHub Issues.

## Repository Structure

- `scripts/` — Shell scripts for syncing settings and generating reports
- `config/` — Baseline settings JSON and per-repo overrides
- `.github/workflows/` — CI/CD and scheduled sync workflows
- `.github/actions/` — Composite actions (security-scan, sync-settings,
  update-pre-commit-composite)
- `.claude/skills/` — Reusable skills (`/audit`, `/add-repo-override`,
  `/exclude-repo`)
- `docs/architecture.md` — System architecture overview
- `docs/adr/` — Architecture Decision Records
- `docs/runbooks/` — Operational procedures (exclude repo, add setting,
  handle drift, onboard repo)

## Git Workflow

- Conventional commits required (`type: description`)
- Types: `fix`, `feat`, `docs`, `chore`, `ci`, `refactor`, `test`
- Never commit directly to `main` — use feature branches and PRs
- Squash merge only; PR title becomes commit title
- No AI attribution in commits, code, or content

## Pre-commit Hooks

General, secrets, shell, markdown, GitHub Actions, and conventional
commit hooks — see `.pre-commit-config.yaml` for the full list.

## Claude Code Hooks

- **PostToolUse** on `Edit|Write`: auto-format shell scripts
  (`shellharden --replace`, `chmod +x`) and markdown
  (`markdownlint --fix`)
- Hooks defined in `.claude/settings.json`, scripts in `.claude/hooks/`

## Linting Policy

- All default rules enforced — NO suppressions
- Fix violations directly instead of adding ignore comments
- Markdownlint: MD013 line length 120, tables exempt
- Table separators: `| --- |` with spaces (MD060)

## Shell Scripts

- Must pass `shellcheck` and `shellharden`
- Quote all variables: `"$VAR"` (braces only when needed)
- Scripts must have shebangs and executable permissions
- The Edit tool can strip executable permissions — verify and restore

## Content Rules

- English only
- No hardcoded credentials or account IDs
- Use placeholder values (`YOUR_GITHUB_TOKEN`, etc.)

## CI/CD Pipelines

- `sync-settings.yml` — weekly settings sync + GitHub Issue reports
- `quality-checks.yml` — markdown, YAML, shell, structure, JSON
  schema validation
- `security.yml` — Semgrep SAST + Trivy SCA (via composite action)
- `update-pre-commit-hooks.yml` — weekly auto-update via PR (via
  composite action)

## Composite Actions

- `.github/actions/security-scan/` — reusable Semgrep + Trivy scan
- `.github/actions/sync-settings/` — reusable settings sync with
  outputs for drift detection
- `.github/actions/update-pre-commit-composite/` — reusable
  pre-commit autoupdate + PR creation

## Claude Code Skills

- `/audit` — run a dry-run settings check across all repos
- `/add-repo-override` — add a per-repo exception to overrides.json
- `/exclude-repo` — exclude a repository from governance

## Code Review

- CodeRabbit auto-review via `.coderabbit.yaml`
- GitHub Copilot auto-review via ruleset
- Both reviewers run on every PR

## Settings Sync Details

The sync script (`scripts/sync-repo-settings.sh`) enforces:

1. **Repo settings**: merge strategy, features, auto-merge, branch
   cleanup
2. **Security**: secret scanning, push protection, vulnerability
   alerts
3. **Branch protection**: reviews, CODEOWNERS, linear history,
   conversation resolution
4. **Rulesets**: Copilot code review ruleset on default branch
5. **Labels**: standard issue labels across all repos
6. **Default branch**: ensures all repos use `main`
7. **Metadata**: flags missing descriptions and topics (advisory)
8. **Required files**: LICENSE, README, CODEOWNERS, etc.

Configuration lives in `config/baseline.json` with per-repo
overrides in `config/overrides.json`.
