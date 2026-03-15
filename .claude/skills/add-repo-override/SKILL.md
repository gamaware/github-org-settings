---
name: add-repo-override
description: >-
  Add a per-repo settings override to overrides.json so a specific
  repository can deviate from the baseline. Use this skill whenever the
  user wants to customize settings for one repo, add an exception, or
  says "this repo needs different branch protection" or "override the
  wiki setting for this repo".
disable-model-invocation: true
user-invocable: true
argument-hint: "<repo-name> <setting-path> <value>"
---

# Add Repository Override

Add a per-repo exception to `config/overrides.json`.

## Arguments

`$ARGUMENTS` should be in the format: `<repo-name> <setting-path> <value>`

Examples:

- `my-repo branch_protection.required_status_checks.contexts '["Build","Test"]'`
- `my-repo repo_settings.has_wiki true`

## Steps

1. Read the current `config/overrides.json`
2. Parse `$ARGUMENTS` to extract repo name, setting path, and value
3. Add or update the override for the specified repo
4. Validate the resulting JSON with `jq empty`
5. Show the diff of what changed
6. Remind the user to create a PR for the change
