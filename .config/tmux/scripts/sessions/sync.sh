#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/sync.sh
# ============================================================================
# Purpose:
#   Rebuild the persistent sessions list from currently-live tmux sessions,
#   ordered most-recently-attached first. Pre-existing entries are wiped.
#
# Called from:
#   The shell (by hand), or the picker's Ctrl-s binding. Useful any time the
#   saved list has drifted from reality — the session-created hook only
#   catches FUTURE sessions, so it can't capture sessions that pre-date the
#   hook itself.
#
# Why not auto-run on tmux startup:
#   The system's contract is "no auto-restore on startup, sessions only
#   materialize when picked." A silent auto-sync would contradict that and
#   would also erase the saved entries for killed sessions that the picker
#   could otherwise lazy-recreate. Manual invocation keeps that control
#   with the user.
#
# Behaviour:
#   - Excludes the same patterns save.sh excludes (currently `*float*`).
#   - Captures each session's active pane cwd as the session cwd.
#   - Orders by `#{session_last_attached}` desc (matches save.sh's MRU).
#   - Writes atomically via temp file + mv.
#
# Contract:
#   No arguments. exit 0 on success.
# ============================================================================

set -eu

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
state_file="$state_dir/sessions.list"
mkdir -p "$state_dir"

# Pull (last_attached, name, cwd-of-active-pane) for every live session.
# `#{pane_current_path}` resolves against the session's focused pane —
# the closest tmux concept to "where this session is currently working".
raw="$(tmux list-sessions -F '#{session_last_attached}|#{session_name}|#{pane_current_path}' 2>/dev/null || true)"

if [ -z "$raw" ]; then
  echo "sessions/sync: no live tmux sessions to sync" >&2
  : > "$state_file"
  exit 0
fi

tmp="$(mktemp "$state_file.XXXXXX")"

# Filter floats, sort MRU desc, emit "<name>\t<cwd>" for the file format.
printf '%s\n' "$raw" \
  | awk -F '|' '$2 !~ /float/' \
  | sort -t '|' -k1,1 -rn \
  | awk -F '|' -v OFS='\t' '{print $2, $3}' \
  > "$tmp"

mv "$tmp" "$state_file"

count="$(wc -l < "$state_file" | tr -d ' ')"
echo "sessions/sync: wrote $count entries to $state_file"
