#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Note
# @raycast.mode compact
#
# Optional parameters:
#
# @raycast.icon bear-light.png
# @raycast.iconDark bear-dark.png
#
# @raycast.mode silent

# Documentation:
# @raycast.description Create a new Bear Note
# @raycast.author ivu
# @raycast.authorURL https://raycast.com/ivu

# @raycast.argument1 { "type": "text", "placeholder": "title", "percentEncoded": true, "optional": true}


COMMON_QUERY_STRINGS="open_note=yes&new_window=yes&show_window=yes&edit=yes"

if [ "$1" = "" ]; then
    open "bear://x-callback-url/create?title=Title&$COMMON_QUERY_STRINGS"
else
    open "bear://x-callback-url/create?title=$1&$COMMON_QUERY_STRINGS"
fi
