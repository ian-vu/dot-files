#!/bin/sh
# Toggle the tmux-sidebar pane in the current window and persist the choice in
# @tmux_sidebar_enabled so sidebar-ensure.sh keeps the sidebar off across
# window switches until toggled back on.

WINDOW_ID=$(tmux display-message -p '#{window_id}' 2>/dev/null)
[ -n "$WINDOW_ID" ] || exit 0

SIDEBAR_PANE=$(tmux list-panes -t "$WINDOW_ID" -F '#{pane_id} #{pane_title}' 2>/dev/null \
  | awk '$2 == "tmux-sidebar" { print $1; exit }')

if [ -n "$SIDEBAR_PANE" ]; then
  tmux set -g @tmux_sidebar_enabled 0
  tmux kill-pane -t "$SIDEBAR_PANE" 2>/dev/null
else
  tmux set -g @tmux_sidebar_enabled 1
  "$HOME/.config/tmux/scripts/sidebar-ensure.sh" "$WINDOW_ID"
fi

exit 0
