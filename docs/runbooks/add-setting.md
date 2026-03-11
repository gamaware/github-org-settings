# Add a New Setting

Enforce a new GitHub setting across all repositories.

## Steps

1. Identify the GitHub API field name for the setting. Check the
   [GitHub REST API docs](https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#update-a-repository)

2. Add the field to the appropriate section in `config/baseline.json`:
   - `repo_settings` — repository-level toggles
   - `security` — security features
   - `branch_protection` — branch protection rules
   - `labels` — standard labels
   - `required_files` — files that must exist

3. Update `scripts/sync-repo-settings.sh` if the new setting requires
   a different API endpoint or comparison logic

4. Update `README.md` to document the new setting and its purpose

5. Test locally:

   ```bash
   ./scripts/sync-repo-settings.sh --dry-run
   ```

6. Create a PR. Review the dry-run output to confirm the expected
   changes

7. After merge, the next weekly run will apply the setting. For
   immediate application, trigger manually:

   ```bash
   gh workflow run sync-settings.yml -f mode="--apply"
   ```

## Per-Repo Exceptions

If a repo legitimately needs a different value, add an override in
`config/overrides.json` under the repo name.
