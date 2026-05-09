#!/usr/bin/env bash
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target opencode config directory
TARGET_DIR="${HOME}/.config/opencode"

# Ensure target directory exists
mkdir -p "${TARGET_DIR}"

echo "Installing opencode config from ${SCRIPT_DIR} to ${TARGET_DIR}..."

# Copy opencode.json (or merge if opencode.jsonc exists)
if [ -f "${SCRIPT_DIR}/opencode.json" ]; then
    cp "${SCRIPT_DIR}/opencode.json" "${TARGET_DIR}/opencode.json"
    echo "  ✓ opencode.json"
fi

# Copy modes directory
if [ -d "${SCRIPT_DIR}/modes" ]; then
    rm -rf "${TARGET_DIR}/modes"
    cp -r "${SCRIPT_DIR}/modes" "${TARGET_DIR}/modes"
    echo "  ✓ modes/"
fi

# Copy skills directory
if [ -d "${SCRIPT_DIR}/skills" ]; then
    rm -rf "${TARGET_DIR}/skills"
    cp -r "${SCRIPT_DIR}/skills" "${TARGET_DIR}/skills"
    echo "  ✓ skills/"
fi

echo ""
echo "Installation complete!"
