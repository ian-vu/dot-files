#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/rename.sh
# ============================================================================
# Purpose:
#   Keep the saved list in sync on `session-renamed`. Without this, a rename
#   would either leave a stale entry under the old name or split the session
#   across two entries (since rename triggers neither create nor close).
#
# Called from:
#   hooks.conf `session-renamed`.
#
# Hook variables:
#   `#{hook_session_name}` is the OLD name in the session-renamed context;
#   `#{session_name}` is the NEW (post-rename) name. If a future tmux flips
#   that, the "old == new" guard below degrades to a silent no-op rather
#   than corrupting the file.
#
# Contract:
#   $1 = old name (pre-rename)
#   $2 = new name (post-rename)
#   $3 = cwd (optional; if provided, the cwd column is updated too)
#   exit 0 always — hook scripts must not signal failure to tmux.
# ============================================================================

set -u

old="${1:-}"
new="${2:-}"
cwd="${3:-}"

# Skip missing args, no-op renames, and float sessions (never saved).
[ -z "$old" ] || [ -z "$new" ] && exit 0
[ "$old" = "$new" ] && exit 0
case "$old" in *float*) exit 0 ;; esac
case "$new" in *float*) exit 0 ;; esac

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"
[ -f "$state_file" ] || exit 0

# Atomic rewrite. Lines matching $old get rewritten with $new as the name,
# and (if supplied) $cwd as the cwd; otherwise the existing cwd is kept.
tmp="$(mktemp "$state_file.XXXXXX")"
awk -F '\t' -v OFS='\t' -v old="$old" -v new="$new" -v cwd="$cwd" '
  $1 == old {
    if (cwd != "") { print new, cwd } else { print new, $2 }
    next
  }
  { print }
' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
