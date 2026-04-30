#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Config
RALPH_ISSUES_DIR="${RALPH_ISSUES_DIR:-./issues}"
RALPH_PRD_DIR="${RALPH_PRD_DIR:-./prd}"
RALPH_AI_RUNNER="${RALPH_AI_RUNNER:-opencode}"

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [[ "$RALPH_AI_RUNNER" == "opencode" ]]; then
        if ! command -v opencode &> /dev/null; then
            log_error "opencode is not installed. Please install it: https://opencode.ai"
            exit 1
        fi
    elif [[ "$RALPH_AI_RUNNER" == "cursor" ]]; then
        if ! command -v agent &> /dev/null; then
            log_error "Cursor CLI is not installed. Install: curl https://cursor.com/install -fsS | bash"
            exit 1
        fi
    else
        log_error "Unknown AI runner: $RALPH_AI_RUNNER. Use 'opencode' or 'cursor'."
        exit 1
    fi
    
    if ! git rev-parse --git-dir &> /dev/null; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    if ! git diff-index --quiet HEAD --; then
        log_error "Working tree is dirty. Commit or stash changes before running ralph."
        exit 1
    fi
    
    log_success "Prerequisites OK (AI runner: $RALPH_AI_RUNNER)"
}

get_original_branch() {
    git branch --show-current
}

detect_mode() {
    if [[ -d "$RALPH_ISSUES_DIR/open" ]]; then
        echo "local"
    elif command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
        echo "github"
    else
        echo "unknown"
    fi
}

# --- Local mode functions ---

find_issues_for_prd_local() {
    local prd_file="$1"
    local prd_basename
    prd_basename=$(basename "$prd_file")
    
    find "$RALPH_ISSUES_DIR/open" -maxdepth 1 -name "*.md" -type f -exec grep -l "Parent PRD:.*$prd_basename" {} \; 2>/dev/null | sort
}

extract_blockers() {
    local issue_file="$1"
    grep -iE '^(Blocked by|Depends on):' "$issue_file" 2>/dev/null | grep -oE '#[0-9]+' | sed 's/#//' | sort -u
}

is_blocked_local() {
    local issue_file="$1"
    local blockers
    blockers=$(extract_blockers "$issue_file")
    
    if [[ -z "$blockers" ]]; then
        return 1
    fi
    
    local blocked=1
    for ref in $blockers; do
        if find "$RALPH_ISSUES_DIR/open" "$RALPH_ISSUES_DIR/in-progress" -maxdepth 1 -name "*${ref}*.md" -print -quit 2>/dev/null | grep -q .; then
            blocked=0
            break
        fi
    done
    
    return $blocked
}

get_issue_title() {
    local issue_file="$1"
    grep -m1 '^# ' "$issue_file" | sed 's/^# //'
}

move_issue() {
    local issue_file="$1"
    local dest_dir="$2"
    local basename
    basename=$(basename "$issue_file")
    
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
    fi
    
    mv "$issue_file" "$dest_dir/$basename"
}

create_branch() {
    local branch_name="$1"
    
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_warn "Branch $branch_name already exists. Skipping."
        return 1
    fi
    
    git checkout -b "$branch_name"
    echo "$branch_name"
}

cleanup_branch() {
    local branch_name="$1"
    local original_branch="$2"
    
    if git rev-list --count "${original_branch}..${branch_name}" | grep -q "^[1-9]"; then
        log_info "Pushing branch $branch_name..."
        git push -u origin "$branch_name" || log_warn "Failed to push branch"
    else
        log_info "No commits on $branch_name. Skipping push."
    fi
    
    git checkout "$original_branch"
}

build_prompt() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local parent_ref="$4"
    
    cat <<EOF
You are working on issue #${issue_number}: "${title}"

Parent PRD: ${parent_ref}

## Task
Implement the feature described below.

## Context
${body}

Please implement this feature. Create commits on the current branch as needed.
EOF
}

run_ai() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local parent_ref="$4"
    
    log_info "Running $RALPH_AI_RUNNER for issue #$issue_number: $title"
    
    local prompt
    prompt=$(build_prompt "$issue_number" "$title" "$body" "$parent_ref")
    
    if [[ "$RALPH_AI_RUNNER" == "opencode" ]]; then
        opencode run "$prompt"
    elif [[ "$RALPH_AI_RUNNER" == "cursor" ]]; then
        agent -p "$prompt" --output-format text
    fi
}

process_issue_local() {
    local issue_file="$1"
    local prd_file="$2"
    local original_branch="$3"
    
    local title
    title=$(get_issue_title "$issue_file")
    local issue_name
    issue_name=$(basename "$issue_file" .md)
    
    if is_blocked_local "$issue_file"; then
        log_warn "Issue $issue_name is blocked. Skipping."
        return 1
    fi
    
    # Move to in-progress
    move_issue "$issue_file" "$RALPH_ISSUES_DIR/in-progress"
    issue_file="$RALPH_ISSUES_DIR/in-progress/$(basename "$issue_file")"
    
    # Create branch
    local branch_name="ralph/$issue_name"
    if ! create_branch "$branch_name"; then
        return 1
    fi
    
    # Build prompt and run
    local body
    body=$(cat "$issue_file")
    local exit_code=0
    
    if ! run_ai "$issue_name" "$title" "$body" "$prd_file"; then
        exit_code=1
    fi
    
    # Cleanup
    cleanup_branch "$branch_name" "$original_branch"
    
    # Move to final state
    if [[ $exit_code -eq 0 ]]; then
        move_issue "$issue_file" "$RALPH_ISSUES_DIR/done"
        log_success "Issue $issue_name completed"
    else
        move_issue "$issue_file" "$RALPH_ISSUES_DIR/failed"
        log_error "Issue $issue_name failed"
    fi
    
    return 0
}

process_next_issue_local() {
    local prd_file="$1"
    local original_branch
    original_branch=$(get_original_branch)
    
    local issues
    issues=$(find_issues_for_prd_local "$prd_file")
    
    if [[ -z "$issues" ]]; then
        return 1
    fi
    
    while IFS= read -r issue_file; do
        if [[ -n "$issue_file" ]]; then
            if process_issue_local "$issue_file" "$prd_file" "$original_branch"; then
                return 0
            fi
        fi
    done <<< "$issues"
    
    return 1
}

# --- GitHub mode functions ---

check_github_prerequisites() {
    if ! command -v gh &> /dev/null; then
        log_error "gh CLI is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null 2>&1; then
        log_error "Not authenticated with gh CLI. Run: gh auth login"
        exit 1
    fi
}

fetch_child_issues() {
    local parent_number="$1"
    
    log_info "Fetching child issues of parent PRD #$parent_number..."
    
    local issues_json
    issues_json=$(gh issue list \
        --search "#${parent_number} in:body" \
        --state open \
        --json number,title,body,labels,assignees \
        --jq '[.[] | select(.assignees | length == 0)]')
    
    echo "$issues_json"
}

is_blocked_github() {
    local issue_body="$1"
    local blocked_refs
    blocked_refs=$(echo "$issue_body" | grep -oE '#[0-9]+' | sed 's/#//')
    
    if [[ -z "$blocked_refs" ]]; then
        return 1
    fi
    
    for ref in $blocked_refs; do
        local state
        state=$(gh issue view "$ref" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
        if [[ "$state" == "OPEN" ]]; then
            return 0
        fi
    done
    
    return 1
}

get_next_issue_github() {
    local issues_json="$1"
    local sorted_issues
    sorted_issues=$(echo "$issues_json" | jq -s 'sort_by(.number) | .[]')
    
    while IFS= read -r issue; do
        if [[ -z "$issue" ]]; then
            continue
        fi
        
        local number title body labels
        number=$(echo "$issue" | jq -r '.number')
        title=$(echo "$issue" | jq -r '.title')
        body=$(echo "$issue" | jq -r '.body')
        labels=$(echo "$issue" | jq -r '.labels[].name' 2>/dev/null || true)
        
        if echo "$labels" | grep -qE "^(ralph-done|ralph-in-progress)$"; then
            continue
        fi
        
        if is_blocked_github "$body"; then
            log_warn "Issue #$number is blocked by open issues. Skipping."
            continue
        fi
        
        echo "$issue"
        return 0
    done <<< "$sorted_issues"
    
    return 1
}

label_issue() {
    local issue_number="$1"
    local label="$2"
    
    log_info "Labeling issue #$issue_number as $label..."
    gh issue edit "$issue_number" --add-label "$label" || true
}

process_issue_github() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local parent_number="$4"
    local original_branch="$5"
    
    local branch_name="ralph/issue-${issue_number}"
    
    if ! create_branch "$branch_name"; then
        return 1
    fi
    
    label_issue "$issue_number" "ralph-in-progress"
    
    local exit_code=0
    if ! run_ai "$issue_number" "$title" "$body" "$parent_number"; then
        exit_code=1
    fi
    
    cleanup_branch "$branch_name" "$original_branch"
    
    if [[ $exit_code -eq 0 ]]; then
        label_issue "$issue_number" "ralph-done"
        log_success "Issue #$issue_number completed"
    else
        label_issue "$issue_number" "ralph-failed"
        log_error "Issue #$number failed"
    fi
    
    return 0
}

process_next_issue_github() {
    local parent_number="$1"
    local original_branch
    original_branch=$(get_original_branch)
    
    local issues_json
    issues_json=$(fetch_child_issues "$parent_number")
    
    local count
    count=$(echo "$issues_json" | jq 'length')
    log_info "Found $count open, unassigned child issues"
    
    if [[ "$count" -eq 0 ]]; then
        return 1
    fi
    
    local next_issue
    next_issue=$(get_next_issue_github "$issues_json")
    
    if [[ -z "$next_issue" ]]; then
        log_warn "No unblocked, unprocessed issues available"
        return 1
    fi
    
    local number title body
    number=$(echo "$next_issue" | jq -r '.number')
    title=$(echo "$next_issue" | jq -r '.title')
    body=$(echo "$next_issue" | jq -r '.body')
    
    log_info "Selected issue #$number: $title"
    
    process_issue_github "$number" "$title" "$body" "$parent_number" "$original_branch"
}
