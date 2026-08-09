#!/bin/sh
# Repair tmux-sidebar pane widths after resizes.
#
# @tmux_sidebar_width is the width authority; observed widths are never
# persisted back. Only sidebar panes whose width differs get resize-pane.
#
# Storm protection (this script runs from resize hooks, and its own
# resize-pane re-fires those hooks):
#   1. Pause flag: the sidebar TUI sets @tmux_sidebar_repair_pause while the
#      user is interactively adjusting the width (the authority changes every
#      keypress); repairing mid-adjust would fight the user and fan out one
#      repair per sidebar pane per keypress.
#   2. Debounce lock: an atomic mkdir lock skips re-entrant runs. Without it,
#      each resize-pane below re-fires the hooks before this run exits,
#      stacking concurrent repairs; enough hung tmux clients once exhausted
#      the server's fd limit and crashed tmux.
# The final state stays correct because the sidebar triggers one repair after
# leaving resize mode, and any later hook fire re-checks all panes.

PAUSED=$(tmux show -gqv @tmux_sidebar_repair_pause 2>/dev/null)
[ "$PAUSED" = "1" ] && exit 0

WIDTH=$(tmux show -gqv @tmux_sidebar_width 2>/dev/null)
[ -n "$WIDTH" ] || exit 0

LOCK_DIR="${TMPDIR:-/tmp}/tmux-sidebar-repair.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # A repair is already running (or crashed <5s ago); it will converge.
  # Stale-lock recovery: locks older than 5s are removed so a killed repair
  # cannot disable width repair forever.
  LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) ))
  [ "$LOCK_AGE" -lt 5 ] && exit 0
  rmdir "$LOCK_DIR" 2>/dev/null || exit 0
  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

tmux list-panes -a -F '#{pane_id} #{pane_title} #{pane_width}' 2>/dev/null \
  | while read -r PANE_ID TITLE PANE_WIDTH; do
      [ "$TITLE" = "tmux-sidebar" ] || continue
      [ "$PANE_WIDTH" = "$WIDTH" ] && continue
      tmux resize-pane -t "$PANE_ID" -x "$WIDTH" 2>/dev/null || true
    done

exit 0
