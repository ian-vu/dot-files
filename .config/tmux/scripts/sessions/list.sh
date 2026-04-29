#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/list.sh
# ============================================================================
# Purpose:
#   Print the picker's default session list: saved entries (MRU-ordered)
#   followed by any live tmux sessions not already in the saved list.
#
#   Merging the two protects against live-but-unsaved sessions becoming
#   invisible. That happens when the session-created hook missed the
#   creation (session predates the hook config, hook errored, etc.) — the
#   session is in `tmux ls` but not in sessions.list, so a saved-only view
#   would hide it.
#
# Called from:
#   - picker.sh (initial fzf input AND the Ctrl-t reload binding).
#
# Contract:
#   No arguments. Prints one session name per line. Excludes the current
#   session and *float* sessions. Exit 0 always.
# ============================================================================

set -u

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"
current_session="$(tmux display -p '#S' 2>/dev/null || echo '')"

saved=""
if [ -f "$state_file" ]; then
  saved="$(awk -F '\t' -v cur="$current_session" '$1 != cur {print $1}' "$state_file")"
fi

# Live sessions, MRU by `#{session_last_attached}` desc. Same filtering
# rules as picker.sh's list_active so the two views stay consistent.
active="$(
  tmux list-sessions -F '#{session_last_attached}|#{session_name}' 2>/dev/null \
    | awk -F '|' -v cur="$current_session" '$2 != cur && $2 !~ /float/' \
    | sort -t '|' -k1,1 -rn \
    | awk -F '|' '{print $2}'
)"

# `awk '!seen[$0]++'` dedupes while preserving first-seen order: saved's
# MRU ordering wins, and live-only sessions are appended at the bottom.
printf '%s\n%s\n' "$saved" "$active" | awk 'NF && !seen[$0]++'
