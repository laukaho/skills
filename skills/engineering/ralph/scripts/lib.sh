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

# --- PRD Branch Management ---

get_prd_branch_name() {
    local prd_ref="$1"
    
    if [[ "$prd_ref" =~ ^[0-9]+$ ]]; then
        echo "ralph/prd-${prd_ref}"
    else
        local prd_basename
        prd_basename=$(basename "$prd_ref" .md)
        echo "ralph/prd-${prd_basename}"
    fi
}

ensure_prd_branch() {
    local prd_branch="$1"
    local original_branch="$2"
    
    log_info "Ensuring PRD branch $prd_branch..."
    
    if git show-ref --verify --quiet "refs/heads/$prd_branch"; then
        log_info "PRD branch $prd_branch already exists, checking it out..."
        git checkout "$prd_branch"
    else
        log_info "Creating PRD branch $prd_branch from $original_branch..."
        git checkout -b "$prd_branch" "$original_branch"
    fi
    
    echo "$prd_branch"
}

cleanup_prd_branch() {
    local prd_branch="$1"
    local original_branch="$2"
    
    log_info "Cleaning up PRD branch $prd_branch..."
    
    if git rev-list --count "${original_branch}..${prd_branch}" | grep -q "^[1-9]"; then
        log_info "Pushing PRD branch $prd_branch..."
        git push -u origin "$prd_branch" || log_warn "Failed to push PRD branch"
    else
        log_info "No commits on $prd_branch. Skipping push."
    fi
    
    git checkout "$original_branch"
}

# --- Issue Branch Management ---

create_issue_branch() {
    local branch_name="$1"
    local prd_branch="$2"
    
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_warn "Branch $branch_name already exists. Skipping."
        return 1
    fi
    
    git checkout -b "$branch_name" "$prd_branch"
    echo "$branch_name"
}

merge_issue_to_prd() {
    local issue_branch="$1"
    local prd_branch="$2"
    
    log_info "Merging $issue_branch into $prd_branch..."
    
    git checkout "$prd_branch"
    
    if ! git merge --no-edit "$issue_branch" 2>/dev/null; then
        log_warn "Merge conflict when merging $issue_branch into $prd_branch"
        log_warn "Please resolve conflicts manually. Current branch: $prd_branch"
        return 1
    fi
    
    # Delete the issue branch after successful merge
    git branch -D "$issue_branch" 2>/dev/null || true
    log_info "Deleted issue branch $issue_branch"
}

# --- Label Management ---

ensure_label_exists() {
    local label="$1"
    
    if ! gh label list --search "$label" --json name | grep -q "\"$label\""; then
        log_info "Creating label '$label'..."
        gh label create "$label" --color "6e5494" --description "Managed by ralph" 2>/dev/null || {
            log_warn "Failed to create label '$label'. It may already exist."
        }
    fi
}

label_issue() {
    local issue_number="$1"
    local label="$2"
    
    log_info "Labeling issue #$issue_number as $label..."
    ensure_label_exists "$label"
    gh issue edit "$issue_number" --add-label "$label" || true
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
    local prd_branch="$3"
    local original_branch="$4"
    
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
    
    # Create branch from PRD branch
    local branch_name="ralph/$issue_name"
    if ! create_issue_branch "$branch_name" "$prd_branch"; then
        return 1
    fi
    
    # Build prompt and run
    local body
    body=$(cat "$issue_file")
    local exit_code=0
    
    if ! run_ai "$issue_name" "$title" "$body" "$prd_file"; then
        exit_code=1
    fi
    
    # Merge issue branch back into PRD branch
    if ! merge_issue_to_prd "$branch_name" "$prd_branch"; then
        log_error "Failed to merge $branch_name into $prd_branch"
        exit_code=1
    fi
    
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
    local prd_branch="$2"
    local original_branch="$3"
    
    local issues
    issues=$(find_issues_for_prd_local "$prd_file")
    
    if [[ -z "$issues" ]]; then
        return 1
    fi
    
    while IFS= read -r issue_file; do
        if [[ -n "$issue_file" ]]; then
            if process_issue_local "$issue_file" "$prd_file" "$prd_branch" "$original_branch"; then
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

process_issue_github() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local parent_number="$4"
    local prd_branch="$5"
    local original_branch="$6"
    
    local branch_name="ralph/issue-${issue_number}"
    
    if ! create_issue_branch "$branch_name" "$prd_branch"; then
        return 1
    fi
    
    label_issue "$issue_number" "ralph-in-progress"
    
    local exit_code=0
    if ! run_ai "$issue_number" "$title" "$body" "$parent_number"; then
        exit_code=1
    fi
    
    # Merge issue branch back into PRD branch
    if ! merge_issue_to_prd "$branch_name" "$prd_branch"; then
        log_error "Failed to merge $branch_name into $prd_branch"
        exit_code=1
    fi
    
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
    local prd_branch="$2"
    local original_branch="$3"
    
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
    
    process_issue_github "$number" "$title" "$body" "$parent_number" "$prd_branch" "$original_branch"
}
