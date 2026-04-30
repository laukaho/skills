#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

usage() {
    echo "Usage: $0 <prd-file|parent-issue-number>"
    echo ""
    echo "Processes the next available unblocked child issue for the given PRD."
    echo ""
    echo "Examples:"
    echo "  $0 prd/001-auth.md          # Local mode"
    echo "  $0 42                        # GitHub mode"
    exit 1
}

main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi
    
    local target="$1"
    
    check_prerequisites
    
    local mode
    mode=$(detect_mode)
    
    if [[ "$mode" == "local" ]]; then
        if [[ ! -f "$target" ]]; then
            log_error "PRD file not found: $target"
            exit 1
        fi
        
        if ! process_next_issue_local "$target"; then
            log_info "No available issues to process"
            exit 0
        fi
    elif [[ "$mode" == "github" ]]; then
        check_github_prerequisites
        
        if ! [[ "$target" =~ ^[0-9]+$ ]]; then
            log_error "For GitHub mode, provide a numeric issue number"
            exit 1
        fi
        
        if ! process_next_issue_github "$target"; then
            log_info "No available issues to process"
            exit 0
        fi
    else
        log_error "Cannot detect mode. Ensure either:"
        log_error "  - Local: $RALPH_ISSUES_DIR/open/ directory exists"
        log_error "  - GitHub: gh CLI is installed and authenticated"
        exit 1
    fi
}

main "$@"
