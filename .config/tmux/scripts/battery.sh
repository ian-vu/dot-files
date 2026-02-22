#!/bin/sh
# Battery percentage for tmux status bar
# Reads battery level from macOS pmset
# Background color changes at thresholds (inverted - low is bad):
#   < 5% = red (#f7768e)
#   < 15% = yellow (#e0af68)
#   otherwise = default (inherits from tmux config)

val=$(pmset -g batt 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d '%')

if [ "$val" -lt 5 ] 2>/dev/null; then
  printf '#[bg=#f7768e,fg=#1b1d2b] 󰂎 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
elif [ "$val" -lt 15 ] 2>/dev/null; then
  printf '#[bg=#e0af68,fg=#1b1d2b] 󰂎 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
else
  printf '󰂎 %s%%' "$val"
fi
