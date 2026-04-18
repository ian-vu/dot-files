#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/remove.sh
# ============================================================================
# Purpose:
#   Drop "$1"'s entry from the persistent sessions list when a session is
#   killed. Hook-driven so any kill (picker Ctrl-x, :kill-session, CLI)
#   converges on a single removal path.
#
# Called from:
#   hooks.conf `session-closed`.
#
# kill-server guard:
#   `tmux kill-server` fires `session-closed` for every dying session as
#   the server tears itself down. Without a guard those cascading hooks
#   would wipe the entire saved list — destroying exactly what we want to
#   preserve across restarts. The guard distinguishes:
#     - Normal kill of one session of many: `tmux list-sessions` succeeds
#       and prints the OTHER live sessions.
#     - Server shutting down: `tmux list-sessions` errors (socket gone) or
#       returns nothing (the closed session was the last). Skip removal.
#
# Contract:
#   $1 = session name (from `#{hook_session_name}`).
#   exit 0 in all tolerable cases (no-op, removed, or server dying).
# ============================================================================

set -u

name="${1:-}"
[ -z "$name" ] && exit 0  # nothing to do, hook fired with empty name

# kill-server guard — see header for full reasoning.
remaining="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"
if [ -z "$remaining" ]; then
  exit 0
fi

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"
[ -f "$state_file" ] || exit 0  # nothing saved yet, nothing to remove

# Atomic rewrite filtering out any line whose name column matches.
# `awk -v` keeps the comparison literal (safe for regex metacharacters).
tmp="$(mktemp "$state_file.XXXXXX")"
awk -F '\t' -v n="$name" '$1 != n' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
