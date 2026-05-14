#!/usr/bin/env bash
# Generate a work summary filename from git metadata and topic keywords.
# Usage: make-filename.sh <keywords> [directory]
#   keywords: 2-4 lowercase words joined with underscores, such as "feed_updates"

set -euo pipefail

keywords="${1:?Usage: make-filename.sh <keywords> [directory]}"
dir="${2:-.}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
metadata=$("$script_dir/get-metadata.sh" "$dir")

get() { echo "$metadata" | awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }'; }

date_val=$(get date)
repo=$(get repo)
context_slug=$(get context_slug)

parts=("$date_val")
[[ -n "$repo" ]] && parts+=("$repo")
[[ -n "$context_slug" ]] && parts+=("$context_slug")
parts+=("$keywords")

IFS='@' ; echo "${parts[*]}.md"
