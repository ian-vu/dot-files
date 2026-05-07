#!/bin/bash

# Make this executable with: chmod +x ~/.claude/notify_on_finish_script.sh

# install it by adding the following to your ~/.claude/settings.json or similar;
# this can also be done by using the "claude-based helper" /hooks command
#
# ```json
# {
#   "hooks": {
#     "PostToolUse": [
#       {
#         "matcher": "*",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "/bin/bash ~/.claude/notify_on_finish_script.sh"
#           }
#         ]
#       }
#     ]
#   }
# }
# ```

# Read the JSON data passed from Claude Code
INPUT=$(cat)

# if you want to see what the json actually looks like, uncomment the following
# this can be used for example to tune the MESSAGE you want to send
# echo "$INPUT" > ~/.claude/notify_on_finish_script_json_out.json

# get the MESSAGE to print in the notification
SESSION_ID=$(echo "$INPUT" | jq -r ".session_id")
MESSAGE="$(cat /tmp/claude_code_session_${SESSION_ID}_prompt)"

# Build notification title: ⟫ session  ⧉  window
TITLE="⟫"
if [ -n "$TMUX" ]; then
  TMUX_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
  TMUX_WINDOW=$(tmux display-message -p '#W' 2>/dev/null)
  # Window names may contain hook status suffixes; strip before using in title.
  TMUX_WINDOW="${TMUX_WINDOW% ⚡}"
  TMUX_WINDOW="${TMUX_WINDOW% 🔔}"
  if [ -n "$TMUX_SESSION" ]; then
    TITLE="$TMUX_SESSION"
    if [ -n "$TMUX_WINDOW" ]; then
      TITLE="$TITLE  ⧉  $TMUX_WINDOW"
    fi
  fi
fi

# Update tmux window name: replace ⚡ with 🔔 when Claude finishes in a
# background window. The bell lives only on the window, never on the session.
if [ -n "$TMUX" ] && [ -f "/tmp/claude_code_session_${SESSION_ID}_window" ]; then
  WINDOW_ID=$(cat "/tmp/claude_code_session_${SESSION_ID}_window")
  CURRENT_NAME=$(tmux display-message -t "$WINDOW_ID" -p '#W' 2>/dev/null)
  CLEAN_NAME="${CURRENT_NAME% ⚡}"
  CLEAN_NAME="${CLEAN_NAME% 🔔}"
  ACTIVE_WINDOW=$(tmux display-message -p '#{window_id}' 2>/dev/null)
  if [ "$WINDOW_ID" != "$ACTIVE_WINDOW" ]; then
    tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME 🔔"
  else
    tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME"
  fi
fi

# Debounce: skip if a notification was sent within the last 10 seconds.
# Both Stop and Notification hooks call this script, and they can fire
# close together for the same turn, causing duplicate notifications.
LOCK_FILE="/tmp/claude_code_notify_${SESSION_ID}_last"
NOW=$(date +%s)
if [ -f "$LOCK_FILE" ]; then
  LAST=$(cat "$LOCK_FILE")
  if [ $((NOW - LAST)) -lt 10 ]; then
    exit 0
  fi
fi
echo "$NOW" > "$LOCK_FILE"

# Send the notification
terminal-notifier -title "$TITLE" \
  -message "$MESSAGE" \
  -sound Pong
