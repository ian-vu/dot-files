#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/connect.sh
# ============================================================================
# Purpose:
#   Resolve a selection string to a tmux session and switch/attach. The
#   single entry point shared by the picker and the `t` shell wrapper.
#
#   Resolution order (first match wins):
#     1. Live tmux session by that name        -> switch/attach.
#     2. Entry in the saved list               -> lazy-create at saved cwd.
#     3. Filesystem path (zoxide/fd result)    -> create named after basename
#                                                 with that path as cwd.
#
# Called from:
#   - scripts/sessions/picker.sh (after fzf selection)
#   - bin/t                      (when given an arg)
#
# Contract:
#   $1 = selection string (session name OR path).
#   exit 0 on success, non-zero on usage error.
# ============================================================================

set -u

selection="${1:-}"
[ -z "$selection" ] && exit 1

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"

# go() — switch if we're inside tmux ($TMUX set), attach otherwise.
# `switch-client` requires a current client; only `attach` works from outside.
go() {
  local target="$1"
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$target"
  else
    tmux attach -t "$target"
  fi
}

# Case 1: live session — switch, then bump the saved entry to the top so the
# picker's MRU ordering reflects this access. The save.sh call is needed
# because no session-created hook fires for plain switches; without an
# explicit bump, switching would leave the saved-list order untouched.
# Passing no cwd tells save.sh to preserve the existing cwd.
#
# `-t "=NAME"` forces EXACT match. Without the `=` prefix, tmux falls back
# to prefix matching, which silently fails (rc=1) when the prefix is
# ambiguous — e.g. picking `dot-files` while `dot-files/wt/...` also exists.
# The fall-through then lazy-creates a duplicate.
if tmux has-session -t "=$selection" 2>/dev/null; then
  go "$selection"
  "$HOME/.config/tmux/scripts/sessions/save.sh" "$selection"
  exit 0
fi

# Case 2: saved-list entry — lazy-create at the saved cwd. The `-A` flag
# is defensive against a race where another client created the session
# between our case-1 check and now.
# Falling back to $HOME on a deleted saved cwd avoids dead-ending the picker
# when a worktree has been removed since the entry was saved.
if [ -f "$state_file" ]; then
  saved_cwd="$(awk -F '\t' -v n="$selection" '$1 == n {print $2; exit}' "$state_file")"
  if [ -n "$saved_cwd" ]; then
    [ -d "$saved_cwd" ] || saved_cwd="$HOME"

    # Worktree sessions should be unique per worktree path. If a stale saved
    # name points at a worktree that is already live under a renamed session,
    # switch to the live session instead of lazy-creating a duplicate.
    case "$selection" in
      */wt/*)
        live_for_cwd="$(
          tmux list-sessions -F '#{session_name}|#{session_path}' 2>/dev/null \
            | awk -F '|' -v cwd="$saved_cwd" '$1 !~ /float/ && $2 == cwd {print $1; exit}'
        )"
        if [ -n "$live_for_cwd" ]; then
          "$HOME/.config/tmux/scripts/sessions/remove.sh" "$selection"
          "$HOME/.config/tmux/scripts/sessions/save.sh" "$live_for_cwd" "$saved_cwd"
          go "$live_for_cwd"
          exit 0
        fi
        ;;
    esac

    tmux new-session -d -A -s "$selection" -c "$saved_cwd"
    go "$selection"
    exit 0
  fi
fi

# Case 3: filesystem path (zoxide / fd result). Derive a session name from
# the basename, sanitising characters tmux disallows in session names
# (`.`, `:`) and spaces.
path="${selection/#\~/$HOME}"
if [ ! -d "$path" ]; then
  tmux display-message "sessions/connect: '$selection' is neither a session nor a directory"
  exit 1
fi

name="$(basename "$path")"
name="${name//./_}"
name="${name//:/_}"
name="${name// /_}"

tmux new-session -d -A -s "$name" -c "$path"
go "$name"
