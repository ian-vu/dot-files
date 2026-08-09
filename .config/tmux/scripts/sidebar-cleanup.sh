#!/bin/sh
# Close any window whose only live pane is the tmux-sidebar.
#
# Without this, killing the last non-sidebar pane (prefix+x, or a shell `exit`)
# leaves a ghost window showing just the sidebar. When the sidebar is the sole
# live pane we close the whole window instead, mirroring prefix+x's last-pane
# behavior ("just close the pane/window").
#
# Runs from after-kill-pane / pane-exited hooks, so it must be cheap and
# idempotent. It only touches windows with exactly one LIVE pane that is the
# sidebar:
#   - Counting live panes only (dead==0) makes the check correct regardless of
#     whether the hook fires before or after the dying pane is removed
#     (after-kill-pane fires while the pane is still listed, pane-exited fires
#     after it is gone).
#   - A window whose only pane is a DEAD sidebar is left alone so
#     sidebar-ensure.sh can respawn it on the next visit.

tmux list-panes -a -F '#{window_id}|#{pane_title}|#{pane_dead}' 2>/dev/null \
  | awk -F'|' '
      {
        win = $1; title = $2; dead = $3
        if (dead == "0") {
          live[win]++
          if (title == "tmux-sidebar") sidebar[win] = 1; else other[win] = 1
        }
      }
      END {
        for (w in live) if (live[w] == 1 && sidebar[w] && !other[w]) print w
      }
    ' \
  | while read -r WIN; do
      # tmux moves the client to another window automatically; killing the last
      # window of a session ends the session, same as prefix+x on the last pane.
      tmux kill-window -t "$WIN" 2>/dev/null
    done

exit 0
