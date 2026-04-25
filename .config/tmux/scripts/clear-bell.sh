#!/bin/sh
# Clears the 🔔 symbol from window and session names when the window gains focus.
# Triggered by tmux's after-select-window and client-session-changed hooks.
# The 🔔 suffix is added by .claude/notify_on_finish_script.sh when Claude
# finishes work in a background window/session.

# Window name cleanup
CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ]; then
  tmux rename-window "$CLEAN_NAME"
fi

# Session name cleanup
SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null)
CLEAN_SESSION="${SESSION_NAME% 🔔}"
if [ "$CLEAN_SESSION" != "$SESSION_NAME" ]; then
  tmux rename-session -t "=$SESSION_NAME" "$CLEAN_SESSION"
fi
