#!/bin/bash

# Make this executable with: chmod +x ~/.claude/write_summary_of_prompt_to_tmp.sh

# install it by adding the following to your ~/.claude/settings.json or similar;
# this can also be done by using the "claude-based helper" /hooks command
#
# ```json
# {
#   "hooks": {
#     "UserPromptSubmit": [
#       {
#         "matcher": "*",
#         "hooks": [
#           {
#             "type": "command",
#             "command": "/bin/bash ~/.claude/write_summary_of_prompt_to_tmp.sh"
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
# echo "$INPUT" > ~/.claude/write_summary_of_prompt_to_tmp_json_out.json

# get the MESSAGE to print in the notification
# a message that says which prompt just returned; the description is an AI summary of the prompt
PROMPT=$(echo "$INPUT" | jq -r ".prompt")
SESSION_ID=$(echo "$INPUT" | jq -r ".session_id")

echo "$PROMPT" >"/tmp/claude_code_session_${SESSION_ID}_prompt"
