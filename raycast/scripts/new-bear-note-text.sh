#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create Note with Text
# @raycast.mode compact
#
# Optional parameters:
#
# @raycast.icon bear-light.png
# @raycast.iconDark bear-dark.png
#
# @raycast.mode silent

# Documentation:
# @raycast.description Create a new Bear Note with Text
# @raycast.author ivu
# @raycast.authorURL https://raycast.com/ivu

# @raycast.argument1 { "type": "text", "placeholder": "text", "percentEncoded": true}


COMMON_QUERY_STRINGS="open_note=yes&new_window=yes&show_window=yes&edit=yes"

open "bear://x-callback-url/create?title=Title&text=$1&$COMMON_QUERY_STRINGS"
