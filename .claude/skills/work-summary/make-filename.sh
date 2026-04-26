#!/usr/bin/env bash
# Generate a work summary filename from metadata + keywords.
# Usage: make-filename.sh <keywords> [directory]
#   keywords: 2-4 lowercase words joined with underscores (e.g. "feed_updates")
#   directory: path to check for git metadata (default: current directory)
# Outputs the filename (without directory prefix).

set -euo pipefail

keywords="${1:?Usage: make-filename.sh <keywords> [directory]}"
dir="${2:-.}"

script_dir="$(cd "$(dirname "$0")" && pwd)"
metadata=$("$script_dir/get-metadata.sh" "$dir")

get() { echo "$metadata" | grep "^$1=" | cut -d= -f2-; }

date_val=$(get date)
repo=$(get repo)
context_slug=$(get context_slug)

parts=("$date_val")
[[ -n "$repo" ]] && parts+=("$repo")
[[ -n "$context_slug" ]] && parts+=("$context_slug")
parts+=("$keywords")

IFS='@' ; echo "${parts[*]}.md"
