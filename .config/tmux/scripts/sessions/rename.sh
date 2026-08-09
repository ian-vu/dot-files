#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/rename.sh
# ============================================================================
# Purpose:
#   Keep the saved list in sync when a session is renamed. A stale saved name
#   can lazy-create a second session for the same worktree, so prefix+$ routes
#   through this script while the old name is still known.
#
# Called from:
#   - key_bindings.conf prefix+$ wrapper with --rename-session.
#   - hooks.conf `session-renamed` as a compatibility fallback. tmux 3.6b
#     exposes only the post-rename name in both hook formats, so that hook is
#     usually a safe no-op on this machine.
#
# Contract:
#   $1 = old name (pre-rename)
#   $2 = new name (post-rename)
#   $3 = cwd (optional; saved with the new name when provided)
#   $4 = --rename-session (optional; perform the tmux rename before saving)
#   exit 0 always — hook scripts must not signal failure to tmux.
# ============================================================================

set -u

old="${1:-}"
new="${2:-}"
cwd="${3:-}"
mode="${4:-}"

# Skip missing args, no-op renames, and float sessions (never saved).
if [ -z "$old" ] || [ -z "$new" ]; then
  exit 0
fi
[ "$old" = "$new" ] && exit 0
case "$old" in *float*) exit 0 ;; esac
case "$new" in *float*) exit 0 ;; esac

if [ "$mode" = "--rename-session" ]; then
  if ! tmux rename-session -t "=$old" "$new" 2>/dev/null; then
    tmux display-message "sessions/rename: failed to rename '$old' to '$new'" 2>/dev/null || true
    exit 0
  fi
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
state_file="$state_dir/sessions.list"
mkdir -p "$state_dir"
[ -f "$state_file" ] || : > "$state_file"

# Preserve the old saved cwd when the caller did not provide one. If the old
# name was never saved, still add the new name so renamed live sessions become
# picker targets.
if [ -z "$cwd" ]; then
  cwd="$(awk -F '\t' -v n="$old" '$1 == n {print $2; exit}' "$state_file")"
  [ -z "$cwd" ] && cwd="$HOME"
fi

# Carry the old entry's first-saved epoch across the rename (a rename is not
# a new session). Falls back to "now" for entries that pre-date the epoch
# field or were never saved.
saved_ts="$(awk -F '\t' -v n="$old" '$1 == n {print $3; exit}' "$state_file")"
[ -z "$saved_ts" ] && saved_ts="$(date +%s)"

# Atomic remove-then-prepend keeps the renamed session MRU and removes any
# stale entries for either the old or new name.
tmp="$(mktemp "$state_file.XXXXXX")"
{
  printf '%s\t%s\t%s\n' "$new" "$cwd" "$saved_ts"
  awk -F '\t' -v old="$old" -v new="$new" '$1 != old && $1 != new' "$state_file"
} > "$tmp" && mv "$tmp" "$state_file"
