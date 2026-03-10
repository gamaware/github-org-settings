# GitHub Organization Settings

Automated governance for GitHub repository settings across the
`gamaware` organization. Ensures consistent configuration, branch
protection, and security practices across all repositories.

## What It Does

- Discovers all repositories in the `gamaware` GitHub account
- Compares current settings against a defined baseline
- Applies standardized settings (merge strategies, branch protection,
  security scanning)
- Runs weekly on a schedule and on every push for validation
- Sends an email report summarizing changes and drift

## Settings Enforced

| Category | Setting | Value |
| --- | --- | --- |
| Merge | Squash merge only | `true` |
| Merge | Merge commit | `false` |
| Merge | Rebase merge | `false` |
| Merge | Squash commit title | `PR_TITLE` |
| Merge | Delete branch on merge | `true` |
| Merge | Allow auto merge | `true` |
| Merge | Allow update branch | `true` |
| Features | Wiki | `false` |
| Features | Projects | `false` |
| Features | Discussions | `false` |
| Features | Issues | `true` |
| Security | Secret scanning | `enabled` |
| Security | Push protection | `enabled` |
| Branch Protection | Required reviews | `1` |
| Branch Protection | Dismiss stale reviews | `true` |
| Branch Protection | Require CODEOWNERS | `true` |
| Branch Protection | Required status checks (strict) | `true` |
| Branch Protection | Required linear history | `true` |
| Branch Protection | Required conversation resolution | `true` |
| Branch Protection | Enforce admins | `false` |

## Repository Structure

```text
github-org-settings/
├── .claude/
│   ├── settings.json
│   └── hooks/
│       └── post-edit.sh
├── .github/
│   ├── workflows/
│   │   ├── sync-settings.yml
│   │   ├── quality-checks.yml
│   │   ├── security.yml
│   │   └── update-pre-commit-hooks.yml
│   ├── actions/
│   │   ├── update-pre-commit-composite/
│   │   │   └── action.yml
│   │   └── security-scan/
│   │       └── action.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── settings-bug.md
│   │   └── settings-request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── copilot-instructions.md
│   └── dependabot.yml
├── scripts/
│   ├── sync-repo-settings.sh
│   └── generate-report.sh
├── config/
│   ├── baseline.json
│   └── overrides.json
├── docs/
│   └── adr/
│       ├── README.md
│       └── 001-settings-governance.md
├── .coderabbit.yaml
├── .gitignore
├── .markdownlint.yaml
├── .yamllint.yml
├── .pre-commit-config.yaml
├── .secrets.baseline
├── zizmor.yml
├── CLAUDE.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── LICENSE
├── SECURITY.md
└── README.md
```

## Usage

### Manual Run

```bash
gh workflow run sync-settings.yml
```

### Local Testing

```bash
# Dry run (validate only, no changes applied)
./scripts/sync-repo-settings.sh --dry-run

# Apply settings
./scripts/sync-repo-settings.sh --apply
```

## Configuration

### Baseline Settings

Edit `config/baseline.json` to change the enforced settings across all
repositories.

### Per-Repo Overrides

Edit `config/overrides.json` to exempt specific repositories from
certain settings.

### Excluded Repositories

Repositories can be excluded entirely by adding them to the `excluded`
array in `config/overrides.json`.

## Author

Jorge Alejandro Garcia Martinez ([@gamaware](https://github.com/gamaware))

## License

[MIT](LICENSE)
