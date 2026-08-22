#!/bin/sh
# Restore a sidebar-aware zoom when the pane that was being worked in exits.
#
# Native tmux zoom drops its zoom state when the zoomed pane exits. The
# sidebar-aware zoom is implemented with pane resizes, so it needs to restore
# its saved layout explicitly or the remaining panes keep the zoom geometry.
# The saved layout may refer to the pane that just exited; tmux can still apply
# the portions belonging to panes that remain, so clear the marker either way.

WINDOW_ID=${1:-}
[ -n "$WINDOW_ID" ] || exit 0

SAVED=$(tmux show-option -w -q -v -t "$WINDOW_ID" @keep_zoom_layout 2>/dev/null)
[ -n "$SAVED" ] || exit 0

tmux select-layout -t "$WINDOW_ID" "$SAVED" 2>/dev/null || true
tmux set-option -w -u -t "$WINDOW_ID" @keep_zoom_layout 2>/dev/null || true

exit 0
