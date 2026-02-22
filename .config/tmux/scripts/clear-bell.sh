#!/bin/sh
# Clears the 🔔 symbol from the window name when the window gains focus
# Triggered by tmux's window-focus-in hook
CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ]; then
  tmux rename-window "$CLEAN_NAME"
fi
