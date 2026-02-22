#!/bin/sh
# Format tmux session name for display in status bar
# Worktree sessions (format: <repo>/wt/<name>) are shown as: repo [name]
# Regular sessions are shown as-is
# Both repo and worktree names are truncated to $max characters
# Usage: format-session.sh <session_name>

s="$1"
max=10

truncate() {
  if [ ${#1} -gt $max ]; then
    printf '%s…' "$(echo "$1" | cut -c1-$max)"
  else
    printf '%s' "$1"
  fi
}

case "$s" in
  */wt/*)
    repo="${s%%/wt/*}"
    wt="${s##*/wt/}"
    printf '%s 󰐅 [%s]' "$(truncate "$repo")" "$(truncate "$wt")"
    ;;
  *)
    printf '%s' "$s"
    ;;
esac
