#!/usr/bin/env bash
# Recreate per-file symlinks from a repo's .work-summaries/ to the Obsidian vault.
# The ignore rule is local-only to avoid changing tracked files in target repos.
# Usage: link-summaries.sh [repo-name] [repo-root]

set -euo pipefail

VAULT_DIR="$HOME/notes/04_Archive/work-summaries"

if [[ ! -d "$VAULT_DIR" ]]; then
  echo "Error: Obsidian vault directory not found: $VAULT_DIR" >&2
  exit 1
fi

repo_name="${1:-}"
repo_root="${2:-}"

if [[ -z "$repo_name" ]]; then
  repo_name=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}' | xargs basename)
  if [[ -z "$repo_name" ]]; then
    echo "Error: not in a git repo and no repo-name provided" >&2
    exit 1
  fi
fi

if [[ -z "$repo_root" ]]; then
  repo_root=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  if [[ -z "$repo_root" ]]; then
    echo "Error: not in a git repo and no repo-root provided" >&2
    exit 1
  fi
fi

ws_dir="$repo_root/.work-summaries"
mkdir -p "$ws_dir"

git_dir=$(git -C "$repo_root" rev-parse --git-dir 2>/dev/null || true)
if [[ -n "$git_dir" ]]; then
  [[ "$git_dir" = /* ]] || git_dir="$repo_root/$git_dir"
  exclude_file="$git_dir/info/exclude"
  mkdir -p "$(dirname "$exclude_file")"
  touch "$exclude_file"
  grep -qxF '.work-summaries/' "$exclude_file" || echo '.work-summaries/' >> "$exclude_file"
fi

count=0
for f in "$VAULT_DIR"/*@"$repo_name"@*.md; do
  [[ -e "$f" ]] || continue
  fname=$(basename "$f")
  ln -sf "$f" "$ws_dir/$fname"
  count=$((count + 1))
done

echo "Linked $count summaries for '$repo_name' in $ws_dir"

