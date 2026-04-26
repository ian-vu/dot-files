#!/usr/bin/env bash
# Generate Obsidian frontmatter + links section for a work summary.
# Usage: make-frontmatter.sh [directory]
#   directory: path to check for git metadata (default: current directory)
# Outputs the full frontmatter block ready to prepend to summary content.

set -euo pipefail

dir="${1:-.}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
metadata=$("$script_dir/get-metadata.sh" "$dir")

get() { echo "$metadata" | grep "^$1=" | cut -d= -f2-; }

date_val=$(get date)
time_val=$(get time)
repo=$(get repo)
branch_slug=$(get branch_slug)

# Build tags array
date_tag="${date_val//\-//}"
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
