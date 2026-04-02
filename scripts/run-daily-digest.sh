#!/bin/bash
# Daily Digest — runs on a schedule via launchd (or cron)
# Logs: ~/.claude/logs/daily-digest.log / daily-digest-error.log

set -euo pipefail

# Load API key for non-interactive launchd context
source "$HOME/.claude/.env"
export ANTHROPIC_API_KEY

CLAUDE="$HOME/.local/bin/claude"

echo "=== Daily Digest started at $(date) ==="

"$CLAUDE" \
  --dangerously-skip-permissions \
  --print "Read $HOME/.claude/daily-digest-agent.md and follow the instructions in that file to generate today's daily digest."

echo "=== Daily Digest finished at $(date) ==="
