#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/save.sh
# ============================================================================
# Purpose:
#   Record a session as "<name>\t<cwd>\t<first_saved_epoch>" in the
#   persistent MRU list and bump it to the top. The picker reads this file in order, so position-in-file
#   IS the recency ranking — no extra timestamps needed.
#
# Called from:
#   - hooks.conf `session-created` (appended via `set-hook -ag` so it
#     coexists with tmux_git_setup). Fires whenever a new session is born.
#   - connect.sh, when switching to an already-live session — that path
#     does not trigger session-created, so we bump explicitly.
#
# Why the cwd is recorded:
#   Lazy-create from the saved list (connect.sh case 2) passes `-c <cwd>`
#   to `tmux new-session`. That cwd is what lets tmux_git_setup detect the
#   repo and rebuild the nvim/lazygit window layout for it. Without the
#   saved cwd, lazy-recreated sessions would all open in $HOME.
#
# Contract:
#   $1 = session name (required, from `#{hook_session_name}` / `#{session_name}`)
#   $2 = session cwd  (optional). One of:
#                     - a path: record it verbatim.
#                     - empty: preserve the existing entry's cwd or fall
#                       back to $HOME. Bump-only callers depend on this.
#                     - `--from-session`: resolve the cwd from the live
#                       session's own `#{session_path}` (the `-c` dir it
#                       was created with). Used by the session-created hook
#                       because `#{pane_current_path}` is unreliable there
#                       (see hooks.conf for why).
#   exit 0 on success, no-op, or tolerable failure - a hook that exits
#   non-zero spams tmux's status line. exit 1 only on usage error.
# ============================================================================

set -u  # NOTE: no -e — a hook that exits non-zero spams tmux's status line.

name="${1:-}"
cwd="${2:-}"

if [ -z "$name" ]; then
  # Defensive: a misconfigured hook passes empty args. Bail silently rather
  # than writing garbage like "<TAB>" to the file.
  exit 1
fi

# Skip *float* sessions: they are popup/throwaway sessions created by
# tmux_float and are not meaningful picker targets.
# (Worktree sessions, `*/wt/*`, ARE saved — they are long-lived and worth
# offering in the picker. Stale entries are handled by connect.sh's
# $HOME-fallback and the picker's Ctrl-x cleanup.)
case "$name" in
  *float*) exit 0 ;;
esac

# Where the persistent list lives. Use XDG_STATE_HOME because this is mutable
# runtime state (changes every time a session is created/renamed/killed),
# not config and not cached data. Falls back to the XDG default.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
state_file="$state_dir/sessions.list"

mkdir -p "$state_dir"
[ -f "$state_file" ] || : > "$state_file"

# --from-session: resolve the cwd from the live session's own working
# directory (`#{session_path}`, i.e. the `-c` dir the session was created
# with). `list-sessions -F` expands `#{session_path}` per-session, so the
# lookup targets the named session regardless of the hook's format context.
# This matters because `#{pane_current_path}` in a session-created hook
# for a detached `new-session -d` issued from another client resolves to
# the TRIGGERING client's pane, not the new session's - which would
# corrupt the saved cwd (e.g. recording ml-scribe's path against a
# dot-files session). Falls back to $HOME if the session is already gone.
if [ "$cwd" = "--from-session" ]; then
  cwd="$(tmux list-sessions -F $'#{session_name}\t#{session_path}' 2>/dev/null \
    | awk -F '\t' -v n="$name" '$1 == n {print $2; exit}')"
  [ -z "$cwd" ] && cwd="$HOME"
fi

# Bump-only call (no cwd given): preserve the existing entry's cwd, or
# fall back to $HOME if no entry exists yet. This avoids ever writing a
# "<name>\t" line with an empty path.
if [ -z "$cwd" ]; then
  cwd="$(awk -F '\t' -v n="$name" '$1 == n {print $2; exit}' "$state_file")"
  [ -z "$cwd" ] && cwd="$HOME"
fi

# File format: one entry per line, "<name>\t<cwd>\t<first_saved_epoch>".
# TAB is the separator because session names and paths can both contain
# spaces, but neither can contain a literal TAB in any sane setup.
# The epoch records when the entry was FIRST saved and survives MRU bumps,
# so the picker preview can show a creation date even for sessions that are
# not currently running. Pre-epoch two-field entries get stamped with "now"
# on their next bump.
saved_ts="$(awk -F '\t' -v n="$name" '$1 == n {print $3; exit}' "$state_file")"
[ -z "$saved_ts" ] && saved_ts="$(date +%s)"
new_line="${name}	${cwd}	${saved_ts}"

# Atomic "remove-then-prepend" via temp file + mv. Prepending (rather than
# updating in place) is what makes the saved list MRU-ordered.
tmp="$(mktemp "$state_file.XXXXXX")"
{
  printf '%s\n' "$new_line"
  awk -F '\t' -v n="$name" '$1 != n' "$state_file"
} > "$tmp" && mv "$tmp" "$state_file"
