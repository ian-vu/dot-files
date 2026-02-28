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
  # Window name may contain ⚡ or 🔔 from hooks; strip before using in title
  TMUX_WINDOW="${TMUX_WINDOW% ⚡}"
  TMUX_WINDOW="${TMUX_WINDOW% 🔔}"
  if [ -n "$TMUX_SESSION" ]; then
    TITLE="$TMUX_SESSION"
    if [ -n "$TMUX_WINDOW" ]; then
      TITLE="$TITLE  ⧉  $TMUX_WINDOW"
    fi
  fi
fi

# Update tmux window name: remove ⚡ (in-progress) and add 🔔 (done)
# Only add 🔔 if the user is not currently in that window
if [ -n "$TMUX" ] && [ -f "/tmp/claude_code_session_${SESSION_ID}_window" ]; then
  WINDOW_ID=$(cat "/tmp/claude_code_session_${SESSION_ID}_window")
  ACTIVE_WINDOW=$(tmux display-message -p '#{window_id}' 2>/dev/null)
  CURRENT_NAME=$(tmux display-message -t "$WINDOW_ID" -p '#W' 2>/dev/null)
  # Strip in-progress symbol (⚡) from window name
  CLEAN_NAME="${CURRENT_NAME% ⚡}"
  if [ "$WINDOW_ID" = "$ACTIVE_WINDOW" ]; then
    # User is in this window, just remove hourglass
    tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME"
  else
    # User is elsewhere, add bell if not already present
    case "$CLEAN_NAME" in
    *🔔) ;;
    *) tmux rename-window -t "$WINDOW_ID" "$CLEAN_NAME 🔔" ;;
    esac
  fi
fi

# Send the notification
terminal-notifier -title "$TITLE" \
  -message "$MESSAGE"
