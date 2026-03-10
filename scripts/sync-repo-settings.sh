#!/usr/bin/env bash
set -euo pipefail

# Sync GitHub repository settings against a defined baseline.
# Usage: sync-repo-settings.sh [--dry-run|--apply]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASELINE="$ROOT_DIR/config/baseline.json"
OVERRIDES="$ROOT_DIR/config/overrides.json"
OWNER="gamaware"
MODE="${1:---dry-run}"
REPORT_FILE="${REPORT_FILE:-$ROOT_DIR/reports/sync-report.md}"

mkdir -p "$(dirname "$REPORT_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Collect all repos for the owner, excluding archived and excluded repos
get_repos() {
    local excluded
    excluded=$(jq -r '.excluded[]' "$OVERRIDES" 2>/dev/null || echo "")
    gh repo list "$OWNER" --no-archived --json name --jq '.[].name' --limit 200 | while read -r repo; do
        if ! echo "$excluded" | grep -qx "$repo"; then
            echo "$repo"
        fi
    done
}

# Get merged settings (baseline + overrides) for a specific repo
get_effective_settings() {
    local repo="$1"
    local override
    override=$(jq -r --arg r "$repo" '.repos[$r] // empty' "$OVERRIDES" 2>/dev/null || echo "")
    if [ -n "$override" ]; then
        jq -s '.[0] * .[1]' "$BASELINE" <(echo "$override")
    else
        cat "$BASELINE"
    fi
}

# Compare and optionally apply repo-level settings
sync_repo_settings() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local changes=""
    local current

    current=$(gh api "repos/$OWNER/$repo" 2>/dev/null) || {
        log "ERROR: Cannot access repos/$OWNER/$repo"
        return 1
    }

    # Build patch payload from baseline repo_settings
    local patch="{}"
    local settings_keys
    settings_keys=$(echo "$effective" | jq -r '.repo_settings | keys[]')

    for key in $settings_keys; do
        local desired current_val
        desired=$(echo "$effective" | jq -r ".repo_settings.$key")
        current_val=$(echo "$current" | jq -r ".$key")

        if [ "$desired" != "$current_val" ]; then
            changes="${changes}- \`$key\`: \`$current_val\` -> \`$desired\`\n"
            patch=$(echo "$patch" | jq --arg k "$key" --argjson v "$(echo "$effective" | jq ".repo_settings.$key")" '. + {($k): $v}')
        fi
    done

    if [ -n "$changes" ]; then
        if [ "$MODE" = "--apply" ]; then
            gh api -X PATCH "repos/$OWNER/$repo" --input <(echo "$patch") > /dev/null 2>&1
            log "APPLIED repo settings for $repo"
        else
            log "DRIFT detected in repo settings for $repo"
        fi
        echo -e "$changes"
    else
        log "OK: repo settings for $repo"
        echo ""
    fi
}

# Compare and optionally apply security settings
sync_security() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local changes=""

    local want_scanning
    want_scanning=$(echo "$effective" | jq -r '.security.secret_scanning')
    local want_push_protection
    want_push_protection=$(echo "$effective" | jq -r '.security.secret_scanning_push_protection')

    local current_security
    current_security=$(gh api "repos/$OWNER/$repo" --jq '.security_and_analysis // empty' 2>/dev/null || echo "")

    local current_scanning="disabled"
    local current_push="disabled"
    if [ -n "$current_security" ]; then
        current_scanning=$(echo "$current_security" | jq -r '.secret_scanning.status // "disabled"')
        current_push=$(echo "$current_security" | jq -r '.secret_scanning_push_protection.status // "disabled"')
    fi

    local desired_scanning_status="disabled"
    local desired_push_status="disabled"
    if [ "$want_scanning" = "true" ]; then desired_scanning_status="enabled"; fi
    if [ "$want_push_protection" = "true" ]; then desired_push_status="enabled"; fi

    if [ "$current_scanning" != "$desired_scanning_status" ] || [ "$current_push" != "$desired_push_status" ]; then
        changes="- Secret scanning: \`$current_scanning\` -> \`$desired_scanning_status\`\n"
        changes="${changes}- Push protection: \`$current_push\` -> \`$desired_push_status\`\n"
        if [ "$MODE" = "--apply" ]; then
            gh api -X PATCH "repos/$OWNER/$repo" --input <(cat <<SECURITY_EOF
{
  "security_and_analysis": {
    "secret_scanning": {"status": "$desired_scanning_status"},
    "secret_scanning_push_protection": {"status": "$desired_push_status"}
  }
}
SECURITY_EOF
            ) > /dev/null 2>&1 || log "WARN: Could not update security settings for $repo (may require admin)"
            log "APPLIED security settings for $repo"
        else
            log "DRIFT detected in security settings for $repo"
        fi
    else
        log "OK: security settings for $repo"
    fi
    echo -e "$changes"
}

# Enable Dependabot vulnerability alerts
sync_vulnerability_alerts() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local changes=""

    local want_alerts
    want_alerts=$(echo "$effective" | jq -r '.security.vulnerability_alerts // false')
    if [ "$want_alerts" != "true" ]; then
        return
    fi

    local current_alerts
    current_alerts=$(gh api "repos/$OWNER/$repo/vulnerability-alerts" -i 2>/dev/null | head -1 || echo "")

    if echo "$current_alerts" | grep -q "204"; then
        log "OK: vulnerability alerts for $repo"
    else
        changes="- Vulnerability alerts: \`disabled\` -> \`enabled\`\n"
        if [ "$MODE" = "--apply" ]; then
            gh api -X PUT "repos/$OWNER/$repo/vulnerability-alerts" > /dev/null 2>&1 \
                || log "WARN: Could not enable vulnerability alerts for $repo"
            log "APPLIED vulnerability alerts for $repo"
        else
            log "DRIFT detected in vulnerability alerts for $repo"
        fi
    fi
    echo -e "$changes"
}

# Compare and optionally apply branch protection
sync_branch_protection() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local changes=""
    local branch
    branch=$(echo "$effective" | jq -r '.branch_protection.branch')

    local current
    current=$(gh api "repos/$OWNER/$repo/branches/$branch/protection" 2>/dev/null) || {
        changes="- Branch protection: **not configured** -> will be created\n"
        if [ "$MODE" = "--apply" ]; then
            apply_branch_protection "$repo" "$branch" "$effective"
        fi
        echo -e "$changes"
        return
    }

    # Check each protection setting
    local current_reviews desired_reviews
    current_reviews=$(echo "$current" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
    desired_reviews=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.required_approving_review_count')

    local current_dismiss desired_dismiss
    current_dismiss=$(echo "$current" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews // false')
    desired_dismiss=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.dismiss_stale_reviews')

    local current_codeowners desired_codeowners
    current_codeowners=$(echo "$current" | jq -r '.required_pull_request_reviews.require_code_owner_reviews // false')
    desired_codeowners=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.require_code_owner_reviews')

    local current_strict desired_strict
    current_strict=$(echo "$current" | jq -r '.required_status_checks.strict // false')
    desired_strict=$(echo "$effective" | jq -r '.branch_protection.required_status_checks.strict')

    local current_linear desired_linear
    current_linear=$(echo "$current" | jq -r '.required_linear_history.enabled // false')
    desired_linear=$(echo "$effective" | jq -r '.branch_protection.required_linear_history')

    local current_conversation desired_conversation
    current_conversation=$(echo "$current" | jq -r '.required_conversation_resolution.enabled // false')
    desired_conversation=$(echo "$effective" | jq -r '.branch_protection.required_conversation_resolution')

    local current_enforce desired_enforce
    current_enforce=$(echo "$current" | jq -r '.enforce_admins.enabled // false')
    desired_enforce=$(echo "$effective" | jq -r '.branch_protection.enforce_admins')

    local drift=false
    if [ "$current_reviews" != "$desired_reviews" ]; then
        changes="${changes}- Required reviews: \`$current_reviews\` -> \`$desired_reviews\`\n"
        drift=true
    fi
    if [ "$current_dismiss" != "$desired_dismiss" ]; then
        changes="${changes}- Dismiss stale reviews: \`$current_dismiss\` -> \`$desired_dismiss\`\n"
        drift=true
    fi
    if [ "$current_codeowners" != "$desired_codeowners" ]; then
        changes="${changes}- Require CODEOWNERS: \`$current_codeowners\` -> \`$desired_codeowners\`\n"
        drift=true
    fi
    if [ "$current_strict" != "$desired_strict" ]; then
        changes="${changes}- Strict status checks: \`$current_strict\` -> \`$desired_strict\`\n"
        drift=true
    fi
    if [ "$current_linear" != "$desired_linear" ]; then
        changes="${changes}- Linear history: \`$current_linear\` -> \`$desired_linear\`\n"
        drift=true
    fi
    if [ "$current_conversation" != "$desired_conversation" ]; then
        changes="${changes}- Conversation resolution: \`$current_conversation\` -> \`$desired_conversation\`\n"
        drift=true
    fi
    if [ "$current_enforce" != "$desired_enforce" ]; then
        changes="${changes}- Enforce admins: \`$current_enforce\` -> \`$desired_enforce\`\n"
        drift=true
    fi

    if [ "$drift" = "true" ]; then
        if [ "$MODE" = "--apply" ]; then
            apply_branch_protection "$repo" "$branch" "$effective"
            log "APPLIED branch protection for $repo"
        else
            log "DRIFT detected in branch protection for $repo"
        fi
    else
        log "OK: branch protection for $repo"
    fi
    echo -e "$changes"
}

apply_branch_protection() {
    local repo="$1"
    local branch="$2"
    local effective="$3"

    local contexts="[]"
    local override_contexts
    override_contexts=$(jq -r --arg r "$repo" '.repos[$r].branch_protection.required_status_checks.contexts // empty' "$OVERRIDES" 2>/dev/null || echo "")
    if [ -n "$override_contexts" ]; then
        contexts=$(jq -r --arg r "$repo" '.repos[$r].branch_protection.required_status_checks.contexts' "$OVERRIDES")
    fi

    local strict
    strict=$(echo "$effective" | jq -r '.branch_protection.required_status_checks.strict')
    local reviews
    reviews=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.required_approving_review_count')
    local dismiss
    dismiss=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.dismiss_stale_reviews')
    local codeowners
    codeowners=$(echo "$effective" | jq -r '.branch_protection.required_pull_request_reviews.require_code_owner_reviews')
    local enforce
    enforce=$(echo "$effective" | jq -r '.branch_protection.enforce_admins')
    local linear
    linear=$(echo "$effective" | jq -r '.branch_protection.required_linear_history')
    local conversation
    conversation=$(echo "$effective" | jq -r '.branch_protection.required_conversation_resolution')
    local force_push
    force_push=$(echo "$effective" | jq -r '.branch_protection.allow_force_pushes')
    local deletions
    deletions=$(echo "$effective" | jq -r '.branch_protection.allow_deletions')

    gh api -X PUT "repos/$OWNER/$repo/branches/$branch/protection" --input <(cat <<PROTECT_EOF
{
  "required_status_checks": {
    "strict": $strict,
    "contexts": $contexts
  },
  "enforce_admins": $enforce,
  "required_pull_request_reviews": {
    "required_approving_review_count": $reviews,
    "dismiss_stale_reviews": $dismiss,
    "require_code_owner_reviews": $codeowners
  },
  "restrictions": null,
  "required_linear_history": $linear,
  "required_conversation_resolution": $conversation,
  "allow_force_pushes": $force_push,
  "allow_deletions": $deletions
}
PROTECT_EOF
    ) > /dev/null 2>&1
}

# Sync standard labels across repos
sync_labels() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local changes=""

    local label_count
    label_count=$(echo "$effective" | jq -r '.labels // [] | length')
    if [ "$label_count" = "0" ]; then
        return
    fi

    local current_labels
    current_labels=$(gh api "repos/$OWNER/$repo/labels" --jq '.[].name' 2>/dev/null || echo "")

    echo "$effective" | jq -c '.labels[]' 2>/dev/null | while read -r label_json; do
        local name color description
        name=$(echo "$label_json" | jq -r '.name')
        color=$(echo "$label_json" | jq -r '.color')
        description=$(echo "$label_json" | jq -r '.description')

        if ! echo "$current_labels" | grep -qx "$name"; then
            changes="${changes}- Label missing: \`$name\`\n"
            if [ "$MODE" = "--apply" ]; then
                gh api -X POST "repos/$OWNER/$repo/labels" \
                    -f name="$name" -f color="$color" -f description="$description" \
                    > /dev/null 2>&1 || log "WARN: Could not create label $name for $repo"
            fi
        fi
    done
    echo -e "$changes"
}

# Check default branch is 'main'
check_default_branch() {
    local repo="$1"
    local changes=""

    local default_branch
    default_branch=$(gh api "repos/$OWNER/$repo" --jq '.default_branch' 2>/dev/null || echo "")

    if [ "$default_branch" != "main" ] && [ -n "$default_branch" ]; then
        changes="- Default branch: \`$default_branch\` (expected \`main\`)\n"
        if [ "$MODE" = "--apply" ]; then
            gh api -X PATCH "repos/$OWNER/$repo" -f default_branch="main" > /dev/null 2>&1 \
                || log "WARN: Could not rename default branch for $repo (may need manual rename)"
            log "APPLIED default branch rename for $repo"
        else
            log "DRIFT detected in default branch for $repo"
        fi
    else
        log "OK: default branch for $repo"
    fi
    echo -e "$changes"
}

# Check for missing description and topics
check_repo_metadata() {
    local repo="$1"
    local changes=""

    local current
    current=$(gh api "repos/$OWNER/$repo" 2>/dev/null) || return

    local description
    description=$(echo "$current" | jq -r '.description // ""')
    if [ -z "$description" ] || [ "$description" = "null" ]; then
        changes="${changes}- **Missing repository description**\n"
    fi

    local topics
    topics=$(echo "$current" | jq -r '.topics | length')
    if [ "$topics" = "0" ]; then
        changes="${changes}- **No repository topics configured**\n"
    fi

    if [ -n "$changes" ]; then
        log "WARN: metadata gaps for $repo"
    else
        log "OK: metadata for $repo"
    fi
    echo -e "$changes"
}

# Check for required files
check_required_files() {
    local repo="$1"
    local effective
    effective=$(get_effective_settings "$repo")
    local missing=""
    local files
    files=$(echo "$effective" | jq -r '.required_files[]')

    for file in $files; do
        if ! gh api "repos/$OWNER/$repo/contents/$file" > /dev/null 2>&1; then
            missing="${missing}- Missing: \`$file\`\n"
        fi
    done
    echo -e "$missing"
}

# Main
main() {
    log "Starting settings sync (mode: $MODE)"
    log "Owner: $OWNER"

    local repos
    repos=$(get_repos)
    local repo_count
    repo_count=$(echo "$repos" | wc -l | tr -d ' ')
    log "Found $repo_count repositories"

    # Initialize report
    cat > "$REPORT_FILE" <<REPORT_HEADER
# GitHub Settings Sync Report

**Date**: $(date '+%Y-%m-%d %H:%M:%S UTC')
**Mode**: $MODE
**Repositories scanned**: $repo_count

REPORT_HEADER

    local total_drift=0
    local total_ok=0

    while read -r repo; do
        [ -z "$repo" ] && continue
        log "Processing: $repo"

        echo "## $repo" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

        local repo_drift=""

        # Default branch
        local branch_changes
        branch_changes=$(check_default_branch "$repo")
        if [ -n "$branch_changes" ]; then
            repo_drift="${repo_drift}### Default Branch\n\n${branch_changes}\n"
        fi

        # Repo settings
        local repo_changes
        repo_changes=$(sync_repo_settings "$repo")
        if [ -n "$repo_changes" ]; then
            repo_drift="${repo_drift}### Repository Settings\n\n${repo_changes}\n"
        fi

        # Security
        local security_changes
        security_changes=$(sync_security "$repo")
        if [ -n "$security_changes" ]; then
            repo_drift="${repo_drift}### Security\n\n${security_changes}\n"
        fi

        # Vulnerability alerts
        local vuln_changes
        vuln_changes=$(sync_vulnerability_alerts "$repo")
        if [ -n "$vuln_changes" ]; then
            repo_drift="${repo_drift}### Vulnerability Alerts\n\n${vuln_changes}\n"
        fi

        # Branch protection
        local protection_changes
        protection_changes=$(sync_branch_protection "$repo")
        if [ -n "$protection_changes" ]; then
            repo_drift="${repo_drift}### Branch Protection\n\n${protection_changes}\n"
        fi

        # Labels
        local label_changes
        label_changes=$(sync_labels "$repo")
        if [ -n "$label_changes" ]; then
            repo_drift="${repo_drift}### Labels\n\n${label_changes}\n"
        fi

        # Metadata (advisory only — not auto-fixed)
        local metadata_changes
        metadata_changes=$(check_repo_metadata "$repo")
        if [ -n "$metadata_changes" ]; then
            repo_drift="${repo_drift}### Metadata (Manual Action Needed)\n\n${metadata_changes}\n"
        fi

        # Required files
        local missing_files
        missing_files=$(check_required_files "$repo")
        if [ -n "$missing_files" ]; then
            repo_drift="${repo_drift}### Missing Files\n\n${missing_files}\n"
        fi

        if [ -n "$repo_drift" ]; then
            echo -e "$repo_drift" >> "$REPORT_FILE"
            total_drift=$((total_drift + 1))
        else
            echo "All settings compliant." >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
            total_ok=$((total_ok + 1))
        fi

    done <<< "$repos"

    # Summary
    cat >> "$REPORT_FILE" <<REPORT_SUMMARY

---

## Summary

| Metric | Count |
| --- | --- |
| Total repositories | $repo_count |
| Compliant | $total_ok |
| Drift detected | $total_drift |
| Mode | $MODE |
REPORT_SUMMARY

    log "Report written to $REPORT_FILE"
    log "Compliant: $total_ok | Drift: $total_drift"
}

main
