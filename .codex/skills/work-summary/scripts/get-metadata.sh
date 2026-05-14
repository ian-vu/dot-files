#!/usr/bin/env bash
# Collect git metadata used to name and tag work summaries.
# Outputs key=value pairs, one per line. Missing git fields are omitted.
# Usage: get-metadata.sh [directory]

set -euo pipefail

dir="${1:-.}"
cd "$dir"

if git rev-parse --git-dir &>/dev/null; then
  main_worktree=$(git worktree list | head -1 | awk '{print $1}')
  repo_name=$(basename "$main_worktree" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
  echo "repo=$repo_name"

  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [[ -n "$branch" ]]; then
    branch_slug=$(echo "$branch" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
    echo "branch=$branch"
    echo "branch_slug=$branch_slug"
  fi

  current_toplevel=$(git rev-parse --show-toplevel 2>/dev/null || true)
  worktree_count=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$worktree_count" -gt 1 && "$current_toplevel" != "$main_worktree" ]]; then
    worktree_name=$(basename "$current_toplevel")
    worktree_slug=$(echo "$worktree_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-20)
    echo "worktree=$worktree_name"
    echo "context_slug=$worktree_slug"
  elif [[ -n "${branch_slug:-}" ]]; then
    echo "context_slug=$(echo "$branch_slug" | cut -c1-20)"
  fi
fi

echo "date=$(date +%Y-%m-%d)"
echo "time=$(date +%H:%M)"
