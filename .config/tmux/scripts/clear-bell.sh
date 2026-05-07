#!/bin/sh
# Clears the 🔔 symbol from the selected window when it gains focus.
# Triggered by tmux's after-select-window and client-session-changed hooks.
# The 🔔 suffix is added by .claude/notify_on_finish_script.sh when Claude
# finishes work in a background window.

CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ]; then
  tmux rename-window "$CLEAN_NAME"
fi
