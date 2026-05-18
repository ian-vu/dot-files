#!/bin/sh
# Clears the 🔔 symbol from the selected window when it gains focus.
# Triggered by tmux's after-select-window and client-session-changed hooks.
# The 🔔 suffix is added by AI agent hooks when work finishes in a background
# window; clearing it here also acknowledges matching native notifications.

CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
WINDOW_ID=$(tmux display-message -p '#{window_id}' 2>/dev/null)
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ]; then
  tmux rename-window "$CLEAN_NAME"
fi

# Remove the grouped Pi notification whenever this window is acknowledged.
# This also covers foreground completions where no 🔔 suffix was added.
TERMINAL_NOTIFIER=$(PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v terminal-notifier 2>/dev/null || true)
if [ -n "$TERMINAL_NOTIFIER" ] && [ -n "$WINDOW_ID" ]; then
  "$TERMINAL_NOTIFIER" -remove "pi-tmux-notify:$WINDOW_ID" >/dev/null 2>&1 || true
fi
