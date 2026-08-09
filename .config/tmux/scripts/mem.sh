#!/bin/sh
# Free memory percentage for tmux status bar (matches btop's "Free" metric)
# Uses vm_stat "Pages free" + "Pages speculative" as a percentage of total
# memory: btop reads the Mach free_count, which includes speculative pages
# (prefetched file cache that is instantly reclaimable), while the vm_stat
# CLI subtracts them from its "Pages free" line. Page size is detected
# dynamically (macOS uses 16384 on Apple Silicon).
# Low free memory correlates with high CPU (memory pressure / swapping),
# so the background warns as free memory drops:
#   < 1% = orange (#ff9e64)
#   otherwise = default (inherits from tmux config)

total=$(sysctl -n hw.memsize 2>/dev/null)
pagesize=$(pagesize 2>/dev/null || echo 16384)

val=$(vm_stat 2>/dev/null | awk -v total="$total" -v ps="$pagesize" '
  /Pages free/        { free = substr($3, 1, length($3)-1) }
  /Pages speculative/ { spec = substr($3, 1, length($3)-1) }
  END {
    printf "%.0f", (free + spec) * ps / total * 100
  }
')

if [ "$val" -lt 1 ] 2>/dev/null; then
  printf '#[bg=#ff9e64,fg=#1b1d2b] 󰘚 %s%% #[bg=#3b4261,fg=#828bb8]' "$val"
else
  # Padding lives inside the script so the segment owns its spacing and the
  # warning background extends edge-to-edge to the separator arrows.
  printf ' 󰘚 %s%% ' "$val"
fi
