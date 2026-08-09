#!/bin/sh
# CPU usage percentage for tmux status bar
# Shows combined user + system CPU usage
# Background color changes at thresholds:
#   > 80% = red (#f7768e)
#   > 60% = yellow (#e0af68)
#   otherwise = default (inherits from tmux config)

val=$(top -l 1 -n 0 -s 0 2>/dev/null | awk '/CPU usage/ {printf "%.0f", $3 + $5}')

if [ "$val" -gt 80 ] 2>/dev/null; then
  printf '#[bg=#f7768e,fg=#1b1d2b] 󰍛 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
elif [ "$val" -gt 60 ] 2>/dev/null; then
  printf '#[bg=#e0af68,fg=#1b1d2b] 󰍛 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
else
  # Padding lives inside the script (all branches) so that when a warning
  # colour is active the background extends edge-to-edge with no default-bg
  # gap next to the separator arrows in status-right.
  printf ' 󰍛 %s%% ' "$val"
fi
