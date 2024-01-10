#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Meeting Note
# @raycast.mode compact
#
# @raycast.icon 📓
# @raycast.iconDark 📓
# @raycast.mode silent

# Documentation:
# @raycast.description Create a new note for a meeting
# @raycast.author ivu
# @raycast.authorURL https://raycast.com/ivu



create_bear_note() {
  COMMON_QUERY_STRINGS="open_note=yes&new_window=yes&show_window=yes&edit=yes"

  # %20 is encoded space
  TITLE="Meeting%20MeetingTitle"
  while IFS= read -r line; do
      if [ -z "$line" ]; then
          # Preserve empty lines
          TEXT+=%0A
      else
          encoded_line=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"$line\"))")
          TEXT+=$encoded_line
          TEXT+=%0A
      fi
  done < meeting-template.md

  DATE=$(date '+%y')
  DATE+=%2F
  DATE+=$(date '+%m')
  DATE+=%2F
  DATE+=$(date '+%d')
  TEXT+="%23meeting%2F$DATE"
  echo $TEXT

  open "bear://x-callback-url/create?title=$TITLE&text=$TEXT"
}

create_bear_note $DATE
