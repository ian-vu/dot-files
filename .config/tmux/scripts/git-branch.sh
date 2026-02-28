#!/bin/sh
# Git branch name for tmux status bar
# Shows the current branch for the pane's working directory
# Truncates to $max characters with '…' suffix if too long
# Usage: git-branch.sh <pane_current_path>

max=6

branch=$(cd "$1" && git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

if [ ${#branch} -gt $max ]; then
  printf '%s…' "$(echo "$branch" | cut -c1-$max)"
else
  printf '%s' "$branch"
fi
