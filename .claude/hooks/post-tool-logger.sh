#!/bin/bash
# LOG hook — records every terraform plan to the deploy log

# Resolve project root from the script's own location (.claude/hooks/ → .claude/ → project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/deploy.log"

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$CMD" | grep -q "terraform plan"; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] terraform plan executed: $CMD" >> "$LOG_FILE"
fi
