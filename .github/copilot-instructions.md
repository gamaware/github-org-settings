Review priorities for this repository:

1. Shell script quality: shellcheck and shellharden compliance, proper
   quoting, error handling (set -euo pipefail), no hardcoded tokens
2. GitHub API usage: correct endpoints, proper error handling, rate
   limit awareness, least-privilege token scopes
3. JSON configuration: valid structure, settings match documented
   baseline, overrides are justified
4. Security: no credential leaks, secrets used properly, tokens never
   logged
5. Workflow security: pinned action versions (SHA references), minimal
   permissions, no script injection
6. Markdown quality: 120 char line limit, fenced code blocks, accurate
   documentation
