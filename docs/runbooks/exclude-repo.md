# Exclude a Repository

Stop syncing settings to a specific repository.

## When to Use

- Third-party forks that must keep upstream settings
- Temporary repos that will be deleted soon
- Repos with fundamentally different governance needs

## Steps

1. Open `config/overrides.json`
2. Add the repo name to the `excluded` array:

   ```json
   {
     "excluded": ["repo-to-exclude"]
   }
   ```

3. Create a PR with the change
4. After merge, the next sync run will skip this repo

## Reverting

Remove the repo name from the `excluded` array and merge the PR.
The next sync run will pick it up again.
