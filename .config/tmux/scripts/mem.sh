#!/bin/sh
# Memory usage percentage for tmux status bar
# Calculates used memory (active + wired + compressed) as a percentage of total
# Uses vm_stat and dynamically detects page size (macOS uses 16384 on Apple Silicon)
# Background color changes at thresholds:
#   > 95% = red (#f7768e)
#   > 80% = yellow (#e0af68)
#   otherwise = default (inherits from tmux config)

total=$(sysctl -n hw.memsize 2>/dev/null)
pagesize=$(pagesize 2>/dev/null || echo 16384)

val=$(vm_stat 2>/dev/null | awk -v total="$total" -v ps="$pagesize" '
  /Pages active/     { active = substr($3, 1, length($3)-1) }
  /Pages wired/      { wired = substr($4, 1, length($4)-1) }
  /Pages compressed/ { compressed = substr($3, 1, length($3)-1) }
  END {
    printf "%.0f", (active + wired + compressed) * ps / total * 100
  }
')

if [ "$val" -gt 95 ] 2>/dev/null; then
  printf '#[bg=#f7768e,fg=#1b1d2b] 󰘚 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
elif [ "$val" -gt 80 ] 2>/dev/null; then
  printf '#[bg=#e0af68,fg=#1b1d2b] 󰘚 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
else
  printf '󰘚 %s%%' "$val"
fi
