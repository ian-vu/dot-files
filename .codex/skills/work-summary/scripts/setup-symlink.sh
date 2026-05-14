#!/usr/bin/env bash
# Create a per-file symlink from repo .work-summaries/ to the Obsidian vault.
# The ignore rule is written to .git/info/exclude so summary links stay local.
# Usage: setup-symlink.sh <filename> [repo-root]

set -euo pipefail

VAULT_DIR="$HOME/notes/04_Archive/work-summaries"

filename="${1:?Usage: setup-symlink.sh <filename> [repo-root]}"
repo_root="${2:-}"

if [[ -z "$repo_root" ]]; then
  repo_root=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  if [[ -z "$repo_root" ]]; then
    echo "Error: not in a git repo and no repo-root provided" >&2
    exit 1
  fi
fi

vault_file="$VAULT_DIR/$filename"
if [[ ! -f "$vault_file" ]]; then
  echo "Error: vault file not found: $vault_file" >&2
  exit 1
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

ln -sf "$vault_file" "$ws_dir/$filename"
echo "$ws_dir/$filename -> $vault_file"

