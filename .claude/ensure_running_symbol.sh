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
    case "$CURRENT_NAME" in
    *⚡) ;; # already has lightning, do nothing
    *)
      tmux rename-window -t "$WINDOW_ID" "$CURRENT_NAME ⚡"
      ;;
    esac

    # Strip 🔔 from session name when work resumes
    CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
    case "$CURRENT_SESSION" in
    *🔔)
      CLEAN_SESSION="${CURRENT_SESSION% 🔔}"
      tmux rename-session "$CLEAN_SESSION"
      ;;
    esac
  fi
} >/dev/null 2>&1
