#!/bin/bash

# Ensures the ⚡ symbol is on the tmux window name while Claude is working.
# This covers gaps where UserPromptSubmit didn't fire (e.g. after plan approval).

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r ".session_id")

# All output must go to /dev/null — PreToolUse hooks must produce no stdout
# (or valid JSON) to avoid "hook error".
{
  if [ -n "$TMUX" ] && [ -f "/tmp/claude_code_session_${SESSION_ID}_window" ]; then
    WINDOW_ID=$(cat "/tmp/claude_code_session_${SESSION_ID}_window")
    CURRENT_NAME=$(tmux display-message -t "$WINDOW_ID" -p '#W' 2>/dev/null)
    CLEAN_NAME="${CURRENT_NAME% ⚡}"
    CLEAN_NAME="${CLEAN_NAME% 🔔}"
    if [ "$CURRENT_NAME" != "$CLEAN_NAME ⚡" ]; then
      tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME ⚡"
    fi
  fi
} >/dev/null 2>&1
