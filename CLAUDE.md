# GitHub Organization Settings — Project Instructions

## Repository Overview

Automated governance for GitHub repository settings across the
`gamaware` organization. Contains shell scripts and GitHub Actions
workflows that discover repos, compare settings against a baseline,
apply corrections, and send email reports.

## Repository Structure

- `scripts/` — Shell scripts for syncing settings and generating reports
- `config/` — Baseline settings JSON and per-repo overrides
- `.github/workflows/` — CI/CD and scheduled sync workflows
- `docs/adr/` — Architecture Decision Records

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

- `sync-settings.yml` — weekly settings sync + email report
- `quality-checks.yml` — markdown, YAML, shell, structure validation
- `security.yml` — Semgrep SAST + Trivy SCA
- `update-pre-commit-hooks.yml` — weekly auto-update via PR

## Code Review

- CodeRabbit auto-review via `.coderabbit.yaml`
- GitHub Copilot auto-review via ruleset
- Both reviewers run on every PR
