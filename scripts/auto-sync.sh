#!/bin/bash
# Auto-syncs ~/daily-digest to GitHub when files change.
# Runs every 15 minutes via launchd.

set -euo pipefail

REPO="$HOME/daily-digest"

cd "$REPO"

if [[ -z "$(git status --porcelain)" ]]; then
  exit 0
fi

git add .
git commit -m "Auto-sync $(date '+%Y-%m-%d %H:%M')"
git push origin master
git push ghe master
