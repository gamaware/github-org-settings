---
name: exclude-repo
description: Exclude a repository from settings governance
user-invocable: true
---

# Exclude Repository

Add a repository to the exclusion list in `config/overrides.json`.

## Arguments

`$ARGUMENTS` should be the repository name to exclude.

## Steps

1. Read the current `config/overrides.json`
2. Add `$ARGUMENTS` to the `excluded` array (if not already present)
3. Validate the resulting JSON with `jq empty`
4. Show the updated exclusion list
5. Remind the user to create a PR for the change
