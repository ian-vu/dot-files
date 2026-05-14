#!/usr/bin/env bash
# Generate Obsidian frontmatter and links for a work summary.
# Usage: make-frontmatter.sh [directory]

set -euo pipefail

dir="${1:-.}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
metadata=$("$script_dir/get-metadata.sh" "$dir")

get() { echo "$metadata" | awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }'; }

date_val=$(get date)
time_val=$(get time)
repo=$(get repo)
branch_slug=$(get branch_slug)

date_tag="${date_val//-/}"
tags="$date_tag"
[[ -n "$repo" ]] && tags="$tags, repo/$repo"
[[ -n "$branch_slug" ]] && tags="$tags, branch/$branch_slug"

cat <<EOF
---
dateCreated: $date_val
timeCreated: $time_val
tags: [$tags]
type: work-summary
---

###### _links:_

[[$date_val]]
[[Work Summaries - Root]]
EOF

[[ -n "$repo" ]] && echo "[[$repo]]"

echo ""
echo "---"
