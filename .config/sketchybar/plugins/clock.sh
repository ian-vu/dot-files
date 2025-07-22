#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

CHARGING="$(pmset -g batt | grep 'AC Power')"

DATE_FORMAT="+%I:%M"

# if [[ "$CHARGING" != "" ]]; then
#   DATE_FORMAT+=":%S"
# fi

DATE_FORMAT+=" %p"

sketchybar --set "$NAME" label="$(date "${DATE_FORMAT}")"
