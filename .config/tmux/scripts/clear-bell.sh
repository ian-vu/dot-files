#!/bin/sh
# Acknowledges the selected pane when it gains focus.
# The 🔔 suffix is window-level, but Pi notifications are pane-level. Keep the
# bell until every pane that requested attention in this window has been focused.
# Clearing a pane here also acknowledges its matching native notification group.

# Prefer hook-expanded targets passed by hooks.conf. Calling display-message
# without an explicit target from async run-shell hooks can read another
# client's current pane and remove the wrong notification group.
WINDOW_ID=${1:-$(tmux display-message -t "${TMUX_PANE:-}" -p '#{window_id}' 2>/dev/null)}
PANE_ID=${2:-${TMUX_PANE:-$(tmux display-message -t "$WINDOW_ID" -p '#{pane_id}' 2>/dev/null)}}
if [ -n "$WINDOW_ID" ]; then
  CURRENT_NAME=$(tmux display-message -t "$WINDOW_ID" -p '#W' 2>/dev/null)
else
  CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
fi

PENDING_OPTION='@pi_tmux_notify_panes'
PENDING_PANES=''
if [ -n "$WINDOW_ID" ]; then
  PENDING_PANES=$(tmux show-option -wqv -t "$WINDOW_ID" "$PENDING_OPTION" 2>/dev/null || true)
fi

NEXT_PENDING=''
for PENDING_PANE in $PENDING_PANES; do
  [ "$PENDING_PANE" = "$PANE_ID" ] && continue
  NEXT_PENDING="$NEXT_PENDING $PENDING_PANE"
done
NEXT_PENDING=${NEXT_PENDING# }

if [ -n "$WINDOW_ID" ]; then
  tmux set-option -wq -t "$WINDOW_ID" "$PENDING_OPTION" "$NEXT_PENDING" 2>/dev/null || true
fi

# Only remove the window bell once all panes with pending AI attention have been
# acknowledged. Older notifications that predate pane tracking still clear when
# there is no tracking option to preserve legacy behavior.
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ] && [ -z "$NEXT_PENDING" ]; then
  if [ -n "$WINDOW_ID" ]; then
    tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME"
  else
    tmux rename-window "$CLEAN_NAME"
  fi
fi

# Acknowledge the tmux-sidebar status file for this pane. Sharing the trigger
# with the notification cleanup below guarantees the sidebar's ✓ and the 🔔
# window marker can never disagree - same trigger, same moment. Only "done"
# files are cleared: this hook fires on every pane focus, and removing a
# "running"/"waiting" file mid-turn would blank the sidebar glyph until the
# next state change (the Pi extension dedupes writes by state).
SIDEBAR_FILE="/tmp/tmux-sidebar/${PANE_ID#%}.json"
if [ -n "$PANE_ID" ] && [ -f "$SIDEBAR_FILE" ] \
    && grep -q '"state"[[:space:]]*:[[:space:]]*"done"' "$SIDEBAR_FILE" 2>/dev/null; then
  rm -f "$SIDEBAR_FILE" 2>/dev/null || true
fi

# Remove the grouped Pi notification whenever this window is acknowledged.
# Alerter powers click actions and grouped notification clearing.
ALERTER=$(PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v alerter 2>/dev/null || true)
if [ -n "$PANE_ID" ]; then
  [ -n "$ALERTER" ] && "$ALERTER" --remove "pi-tmux-notify:$PANE_ID" >/dev/null 2>&1 || true
fi

# Also remove the legacy window-level group used by older versions of the Pi
# extension so stale notifications disappear after this config update.
if [ -n "$WINDOW_ID" ]; then
  [ -n "$ALERTER" ] && "$ALERTER" --remove "pi-tmux-notify:$WINDOW_ID" >/dev/null 2>&1 || true
fi
