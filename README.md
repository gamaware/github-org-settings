# GitHub Organization Settings

Automated governance for GitHub repository settings across the
`gamaware` organization. Discovers all repositories, compares their
configuration against a defined baseline, applies corrections, and
reports drift via GitHub Issues.

## Why This Exists

Manually configuring GitHub repository settings is error-prone and
does not scale. When you create a new repository or change a policy
(e.g., requiring linear history), every repo needs updating. This
automation ensures that all repositories under `gamaware` converge to
a single standard — the same merge strategies, branch protection
rules, security scanning, and scaffolding files.

## How It Works

```text
Weekly (Sunday 00:00 UTC)
        |
        v
+-------------------+
| Discover repos    | -- gh repo list (excludes archived + excluded)
+-------------------+
        |
        v
+-------------------+
| Compare settings  | -- current state vs config/baseline.json
+-------------------+
        |
        v
+-------------------+
| Apply corrections | -- PATCH/PUT via GitHub API (--apply mode)
+-------------------+
        |
        v
+-------------------+
| Generate report   | -- Markdown report + GitHub Issue if drift found
+-------------------+
```

The workflow also checks for repositories created in the last 7 days
and opens a GitHub Issue to flag them.

## What Gets Enforced

### Merge Strategy

Every repository is locked to squash-merge only. This keeps `main`
history linear and readable.

| Setting | Value | Why |
| --- | --- | --- |
| `allow_squash_merge` | `true` | Single clean commit per PR |
| `allow_merge_commit` | `false` | Prevents noisy merge commits |
| `allow_rebase_merge` | `false` | Prevents rebase without squash |
| `squash_merge_commit_title` | `PR_TITLE` | Consistent commit messages |
| `squash_merge_commit_message` | `PR_BODY` | PR description becomes commit body |
| `delete_branch_on_merge` | `true` | Auto-cleanup merged branches |
| `allow_auto_merge` | `true` | Merge automatically when checks pass |
| `allow_update_branch` | `true` | Keep PR branches current with base |

### Repository Features

Unused features are disabled to reduce attack surface and clutter.

| Setting | Value | Why |
| --- | --- | --- |
| `has_wiki` | `false` | Documentation lives in the repo |
| `has_projects` | `false` | Not used for project tracking |
| `has_discussions` | `false` | Not used for discussions |
| `has_issues` | `true` | Primary issue tracker |

### Security

Secret scanning catches leaked credentials before they reach `main`.
Vulnerability alerts flag known CVEs in dependencies.

| Setting | Value | Why |
| --- | --- | --- |
| Secret scanning | `enabled` | Detect leaked tokens and keys |
| Push protection | `enabled` | Block pushes containing secrets |
| Vulnerability alerts | `enabled` | Dependabot CVE notifications |

### Branch Protection (main)

All changes go through PRs with at least one review. Linear history
ensures clean `git log` and bisectability.

| Setting | Value | Why |
| --- | --- | --- |
| Required reviews | `1` | At least one approval before merge |
| Dismiss stale reviews | `true` | New pushes invalidate old approvals |
| Require CODEOWNERS | `true` | Owners must review their areas |
| Required status checks | `strict` | Branch must be up to date |
| Required linear history | `true` | No merge commits on main |
| Required conversation resolution | `true` | All comments must be resolved |
| Enforce admins | `false` | Admins can bypass when needed |

### Rulesets

The Copilot code review ruleset is enforced on every repository's
default branch. The sync script creates it if missing and verifies
enforcement is active.

| Rule | Purpose |
| --- | --- |
| `deletion` | Prevent branch deletion |
| `non_fast_forward` | Prevent force pushes |
| `copilot_code_review` | Require Copilot review on PRs |

### Labels

Standard labels are created on every repo for consistent issue
triage.

| Label | Color | Purpose |
| --- | --- | --- |
| `bug` | red | Something is broken |
| `enhancement` | cyan | New feature or improvement |
| `documentation` | blue | Docs updates |
| `security` | yellow | Security-related |
| `settings-drift` | gold | Settings mismatch (used by this repo) |
| `new-repo` | green | New repo discovered (used by this repo) |

### Required Files

Every repo must contain these files. Missing files are flagged in the
report (not auto-created, since content is repo-specific).

| File | Purpose |
| --- | --- |
| `LICENSE` | Legal terms (MIT) |
| `README.md` | Project overview |
| `.gitignore` | Exclude build artifacts and secrets |
| `CODEOWNERS` | Assign default reviewers |
| `CONTRIBUTING.md` | Contribution guidelines |
| `SECURITY.md` | Vulnerability disclosure policy |
| `.pre-commit-config.yaml` | Local linting and validation |
| `.github/dependabot.yml` | Automated dependency updates |

### Metadata Checks (Advisory)

Repos missing a description or topics are flagged in the report for
manual attention. These are not auto-fixed because they require
human judgment.

### Default Branch Check

Repos not using `main` as the default branch are flagged and can be
corrected in `--apply` mode.

## Repository Structure

```text
github-org-settings/
├── .claude/
│   ├── settings.json               # Claude Code hooks config
│   ├── hooks/
│   │   └── post-edit.sh             # Auto-format on edit
│   └── skills/
│       ├── audit/                   # /audit — dry-run settings check
│       │   └── SKILL.md
│       ├── add-repo-override/       # /add-repo-override — add exception
│       │   └── SKILL.md
│       └── exclude-repo/            # /exclude-repo — exclude a repo
│           └── SKILL.md
├── .github/
│   ├── actions/
│   │   ├── security-scan/           # Composite: Semgrep + Trivy
│   │   │   └── action.yml
│   │   ├── sync-settings/           # Composite: settings sync
│   │   │   └── action.yml
│   │   └── update-pre-commit-composite/  # Composite: hook updates
│   │       └── action.yml
│   ├── workflows/
│   │   ├── sync-settings.yml        # Weekly settings sync + reports
│   │   ├── quality-checks.yml       # PR/push linting and validation
│   │   ├── security.yml             # SAST + SCA scanning
│   │   └── update-pre-commit-hooks.yml  # Weekly hook updates
│   ├── ISSUE_TEMPLATE/
│   │   ├── settings-bug.md
│   │   └── settings-request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── copilot-instructions.md
│   └── dependabot.yml
├── scripts/
│   ├── sync-repo-settings.sh        # Main sync logic
│   └── generate-report.sh           # Report parser for CI
├── config/
│   ├── baseline.json                # Settings enforced on all repos
│   └── overrides.json               # Per-repo exceptions
├── docs/
│   ├── architecture.md              # System architecture overview
│   ├── adr/
│   │   ├── README.md
│   │   ├── 001-settings-governance.md
│   │   └── 002-sync-architecture.md
│   └── runbooks/
│       ├── README.md
│       ├── add-setting.md           # How to add a new setting
│       ├── exclude-repo.md          # How to exclude a repo
│       ├── handle-drift.md          # How to respond to drift
│       └── onboard-repo.md          # How to onboard a new repo
├── .coderabbit.yaml                 # CodeRabbit auto-review config
├── .gitignore
├── .markdownlint.yaml
├── .yamllint.yml
├── .pre-commit-config.yaml
├── .secrets.baseline
├── zizmor.yml                       # GitHub Actions security config
├── CLAUDE.md                        # Claude Code project instructions
├── CODEOWNERS
├── CONTRIBUTING.md
├── LICENSE
├── SECURITY.md
└── README.md
```

## Usage

### Automatic (Weekly)

The `sync-settings.yml` workflow runs every Sunday at midnight UTC in
`--apply` mode. It:

1. Discovers all non-archived repos
2. Compares settings against `config/baseline.json`
3. Applies corrections via the GitHub API
4. Posts a Job Summary with the full report
5. Opens a GitHub Issue if drift was detected
6. Closes previous drift issues if all repos are compliant
7. Flags new repos created in the last 7 days

### Manual Trigger

```bash
# Dry run (validation only)
gh workflow run sync-settings.yml -f mode="--dry-run"

# Apply settings
gh workflow run sync-settings.yml -f mode="--apply"
```

### Local Testing

```bash
# Dry run
./scripts/sync-repo-settings.sh --dry-run

# Apply
./scripts/sync-repo-settings.sh --apply
```

## Configuration

### Baseline Settings

Edit `config/baseline.json` to change the enforced settings. Changes
go through PR review like any code change.

### Per-Repo Overrides

Edit `config/overrides.json` to set repo-specific exceptions. The
most common override is `required_status_checks.contexts` since
each repo has different CI jobs.

### Excluding Repositories

Add repo names to the `excluded` array in `config/overrides.json`:

```json
{
  "excluded": ["some-repo-to-skip"]
}
```

## Secrets Required

| Secret | Purpose | Scopes |
| --- | --- | --- |
| `ORG_SETTINGS_PAT` | GitHub PAT for API access | `repo`, `admin:org` |

## Code Review

- **GitHub Copilot**: auto-review via ruleset (enforced automatically
  by the sync script)
- **CodeRabbit**: auto-review on PRs via `.coderabbit.yaml`

> **Note:** CodeRabbit must be enabled manually per repository through
> the [CodeRabbit dashboard](https://app.coderabbit.ai). No API exists
> to automate this step. After installing the GitHub App, select "All
> repositories" to cover new repos automatically, or add repos
> individually through the dashboard.

## CI/CD Pipelines

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| `sync-settings.yml` | Weekly + manual | Settings enforcement |
| `quality-checks.yml` | PR + push to main | Markdown, YAML, shell, structure |
| `security.yml` | PR + push to main | Semgrep SAST + Trivy SCA |
| `update-pre-commit-hooks.yml` | Weekly + manual | Auto-update hook versions |

## Author

Jorge Alejandro Garcia Martinez
([@gamaware](https://github.com/gamaware))

## License

[MIT](LICENSE)
