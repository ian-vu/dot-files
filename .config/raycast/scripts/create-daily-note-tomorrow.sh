#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Daily Note for Tomorrow
# @raycast.mode compact
#
# @raycast.icon 📓
# @raycast.iconDark 📓
# @raycast.mode silent

# Documentation:
# @raycast.description Create a new daily note for Tomorrow
# @raycast.author ivu
# @raycast.authorURL https://raycast.com/ivu

DATE=$(date -v+1d '+%y%m%d')


create_bear_note() {
  DATE=$1

  COMMON_QUERY_STRINGS="open_note=yes&new_window=yes&show_window=yes&edit=yes"

  # %20 is encoded space
  TITLE="Daily%20$DATE"
  TEXT=$(< daily-note-template.md)

  TEXT=""
  while IFS= read -r line; do
      if [ -z "$line" ]; then
          # Preserve empty lines
          TEXT+=%0A
      else
          encoded_line=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"$line\"))")
          TEXT+=$encoded_line
          TEXT+=%0A
      fi
  done < daily-note-template.md 

  open "bear://x-callback-url/create?title=$TITLE&text=$TEXT"
}

create_bear_note $DATE
