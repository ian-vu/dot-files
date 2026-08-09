#!/usr/bin/env sh
# Kill opensessions-sidebar panes in detached sessions idle longer than a
# grace period (default 30 min; override with $1 in seconds).
#
# Why: the opensessions plugin ensures one sidebar pane per window, and those
# panes persist after the client detaches or switches away. With many
# background sessions this accumulates dozens of idle sidebar TUI processes
# (~0.8% CPU each) that nobody can see, and inflates the system process table
# (which e.g. JamfDaemon's RestrictedSoftwareMonitor rescans continuously -
# more processes means measurably more daemon CPU).
#
# Grace period: reaping every detached sidebar immediately makes session
# switching jumpy - returning to a recently used session forces the plugin to
# respawn the sidebar (pane split + TUI start + layout settle) on every
# switch. Keying off #{session_activity} keeps sidebars warm in sessions used
# within the window, so hopping between active sessions is instant, while
# stale background sessions still get cleaned up.
#
# Safe because: the plugin's ensure-sidebar hooks (after-new-window,
# client-session-changed) respawn a sidebar on demand the moment a client
# attaches or switches to the session, and killing a sidebar pane cleanly
# terminates its process (verified: kill-pane reaps the binary).
#
# Guards:
#   - only panes titled "opensessions-sidebar"
#   - only in sessions with session_attached == 0
#   - only in sessions idle longer than the grace period
#   - never the last pane of a single-window session (killing it would kill
#     the whole session); the plugin's own orphan logic handles that case
#   - the plugin's _os_stash session is left alone (hidden-sidebar storage)
#
# Invoked from hooks.conf on client-session-changed (fires whenever the user
# switches sessions, i.e. exactly when a session becomes "background").

GRACE="${1:-1800}"
NOW="$(date +%s)"

tmux list-panes -a \
  -F '#{session_attached}|#{session_name}|#{session_activity}|#{window_panes}|#{session_windows}|#{pane_id}|#{pane_title}' \
  2>/dev/null |
  while IFS='|' read -r attached session activity window_panes session_windows pane_id title; do
    [ "$title" = "opensessions-sidebar" ] || continue
    [ "$attached" = "0" ] || continue
    [ "$session" = "_os_stash" ] && continue
    # Keep sidebars in recently active sessions so switching back is instant.
    case "$activity" in *[!0-9]*|'') activity=0;; esac
    [ $((NOW - activity)) -ge "$GRACE" ] || continue
    # Skip when the sidebar is the only pane of the only window: kill-pane
    # would destroy the session itself.
    if [ "$window_panes" = "1" ] && [ "$session_windows" = "1" ]; then
      continue
    fi
    tmux kill-pane -t "$pane_id" 2>/dev/null
  done

exit 0
