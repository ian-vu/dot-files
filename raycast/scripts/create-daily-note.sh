#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Daily Note
# @raycast.mode compact
#
# @raycast.icon 📓
# @raycast.iconDark 📓
#

# Documentation:
# @raycast.description Create a new daily note
# @raycast.author ivu
# @raycast.authorURL https://raycast.com/ivu

COMMON_QUERY_STRINGS="open_note=yes&new_window=yes&show_window=yes&edit=yes"

DATE=$(date '+%y%m%d')
TITLE="Daily$DATE"
TEXT=$(< daily-note-template.md)

TEXT=""
while IFS= read -r line; do
    if [ -z "$line" ]; then
        # Preserve empty lines
        TEXT+=%0A
    else
        encoded_line=$(python -c "import urllib.parse; print(urllib.parse.quote(\"$line\"))")
        TEXT+=$encoded_line
        TEXT+=%0A
    fi
done < daily-note-template.md && echo "$TEXT"

# TEXT=$(echo $TEXT)
# TEXT=---%0A%0A---%0Ahello%20wold%0A%0A%0A
# encoded_line=$(python3 -c "import urllib.parse; print(urllib.parse.quote(\"$text\"))")


x_callback_url="bear://x-callback-url/create?title=$TITLE&text=$TEXT"
echo $x_callback_url

open $x_callback_url
