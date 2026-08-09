#!/bin/sh
# Idempotently ensure the current window has a tmux-sidebar pane.
#
# Runs from after-new-window / after-select-window / client-session-changed
# hooks, so it must be cheap and safe to fire repeatedly: if a pane titled
# "tmux-sidebar" already exists in the window, do nothing. Because the hook
# fires the first time any window is visited, pre-existing sessions/windows
# get a sidebar too, and a dead sidebar process respawns on the next visit.
#
# Targets are passed from hooks.conf format expansion; run-shell hooks without
# explicit targets can resolve against another client's active window.

WINDOW_ID=${1:-$(tmux display-message -p '#{window_id}' 2>/dev/null)}
[ -n "$WINDOW_ID" ] || exit 0

# Respect the toggle flag: when the user turned the sidebar off, stay off
# across window switches until toggled back on.
ENABLED=$(tmux show -gqv @tmux_sidebar_enabled 2>/dev/null)
[ "$ENABLED" = "0" ] && exit 0

# Already present? (The sidebar sets its own pane title on startup, but the
# spawn below also sets it immediately so back-to-back hook fires cannot race
# a second split before python gets to select-pane.)
if tmux list-panes -t "$WINDOW_ID" -F '#{pane_title}' 2>/dev/null \
    | grep -qx 'tmux-sidebar'; then
  exit 0
fi

# Width authority lives in @tmux_sidebar_width, seeded once from config.json.
WIDTH=$(tmux show -gqv @tmux_sidebar_width 2>/dev/null)
if [ -z "$WIDTH" ]; then
  CONFIG="$HOME/.config/tmux-sidebar/config.json"
  WIDTH=$(python3 -c 'import json,sys
try:
    print(json.load(open(sys.argv[1])).get("width", 32))
except Exception:
    print(32)' "$CONFIG" 2>/dev/null)
  WIDTH=${WIDTH:-32}
  tmux set -g @tmux_sidebar_width "$WIDTH"
fi

# Remember the active pane, spawn the sidebar on the left edge without focus
# (-d), title it right away, and keep the user's focus where it was.
# -f spans the full window height at the far-left edge; without it the split
# happens inside the active pane, so a right-hand split would get the sidebar
# glued next to it instead of a dedicated left column.
ACTIVE_PANE=$(tmux display-message -t "$WINDOW_ID" -p '#{pane_id}' 2>/dev/null)
SIDEBAR_PANE=$(tmux split-window -fhb -d -l "$WIDTH" -t "$WINDOW_ID" \
  -P -F '#{pane_id}' "python3 $HOME/.local/bin/tmux-sidebar.py" 2>/dev/null)
[ -n "$SIDEBAR_PANE" ] && tmux select-pane -t "$SIDEBAR_PANE" -T 'tmux-sidebar' 2>/dev/null
[ -n "$ACTIVE_PANE" ] && tmux select-pane -t "$ACTIVE_PANE" 2>/dev/null

exit 0
