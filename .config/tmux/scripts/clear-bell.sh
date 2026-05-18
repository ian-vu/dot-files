#!/bin/sh
# Clears the 🔔 symbol from the selected window when it gains focus.
# Triggered by tmux's pane/window/session focus hooks so pane-level Pi work is
# acknowledged even when it finishes in another split in the same window.
# The 🔔 suffix is added by AI agent hooks when work finishes in a background
# pane; clearing it here also acknowledges matching native notifications.

CURRENT_NAME=$(tmux display-message -p '#W' 2>/dev/null)
WINDOW_ID=$(tmux display-message -p '#{window_id}' 2>/dev/null)
CLEAN_NAME="${CURRENT_NAME% 🔔}"
if [ "$CLEAN_NAME" != "$CURRENT_NAME" ]; then
  tmux rename-window "$CLEAN_NAME"
fi

# Remove the grouped Pi notification whenever this window is acknowledged.
# Alerter powers click actions; terminal-notifier remains as a fallback.
ALERTER=$(PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v alerter 2>/dev/null || true)
TERMINAL_NOTIFIER=$(PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" command -v terminal-notifier 2>/dev/null || true)
if [ -n "$WINDOW_ID" ]; then
  [ -n "$ALERTER" ] && "$ALERTER" --remove "pi-tmux-notify:$WINDOW_ID" >/dev/null 2>&1 || true
  [ -n "$TERMINAL_NOTIFIER" ] && "$TERMINAL_NOTIFIER" -remove "pi-tmux-notify:$WINDOW_ID" >/dev/null 2>&1 || true
fi
