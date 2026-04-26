#!/usr/bin/env bash
# Create a per-file symlink from repo .work-summaries/ to the Obsidian vault.
# Also ensures .work-summaries/ exists and is gitignored.
# Usage: setup-symlink.sh <filename> [repo-root]
#   filename: the summary filename (e.g. 2026-04-24@myapp@main@feed_updates.md)
#   repo-root: path to create .work-summaries/ in (default: git repo root)

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

gitignore="$repo_root/.gitignore"
if [[ -f "$gitignore" ]]; then
  grep -qxF '.work-summaries/' "$gitignore" || echo '.work-summaries/' >> "$gitignore"
else
  echo '.work-summaries/' > "$gitignore"
fi

ln -sf "$vault_file" "$ws_dir/$filename"
echo "$ws_dir/$filename -> $vault_file"
