#!/usr/bin/env bash
# Recreate per-file symlinks from a repo's .work-summaries/ to the Obsidian vault.
# Usage: link-summaries.sh [repo-name] [repo-root]
#   repo-name: name to match in filenames (default: basename of current git repo)
#   repo-root: path to create .work-summaries/ in (default: git repo root)

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

gitignore="$repo_root/.gitignore"
if [[ -f "$gitignore" ]]; then
  grep -qxF '.work-summaries/' "$gitignore" || echo '.work-summaries/' >> "$gitignore"
else
  echo '.work-summaries/' > "$gitignore"
fi

count=0
for f in "$VAULT_DIR"/*@"$repo_name"@*.md; do
  [[ -e "$f" ]] || continue
  fname=$(basename "$f")
  ln -sf "$f" "$ws_dir/$fname"
  count=$((count + 1))
done

echo "Linked $count summaries for '$repo_name' in $ws_dir"
