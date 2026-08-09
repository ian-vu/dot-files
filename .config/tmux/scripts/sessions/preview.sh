#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/preview.sh
# ============================================================================
# Purpose:
#   Render the fzf preview pane for the session picker (Ctrl-p toggle in
#   picker.sh). Given one picker selection, print a compact info card:
#     - session basics: created / last-attached datetimes, client count, cwd
#     - git state: branch, dirty count, ahead/behind upstream, last commit
#     - windows: index, name, pane count, active marker
#     - running commands: current command per pane
#
# Called from:
#   - scripts/sessions/picker.sh (`--preview` binding).
#
# Contract:
#   $1 = picker selection (session name OR directory path, same shapes
#        connect.sh accepts). fzf strips the list's ANSI codes before
#        substituting {}, so the argument is plain text.
#   Always exits 0 — a broken preview must not break the picker.
# ============================================================================

set -u

selection="${1:-}"
[ -z "$selection" ] && exit 0

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"

# fzf preview panes render ANSI colors natively.
bold=$'\e[1m'
dim=$'\e[90m'
cyan=$'\e[36m'
green=$'\e[32m'
yellow=$'\e[33m'
red=$'\e[31m'
reset=$'\e[0m'

label() { printf '%s%-10s%s %s\n' "$dim" "$1" "$reset" "$2"; }
section() { printf '\n%s%s%s\n' "$bold" "$1" "$reset"; }

# --- Resolve selection -> live session and/or cwd --------------------------
# Mirrors connect.sh's resolution order so the preview describes what Enter
# would actually connect to: live session > saved entry > filesystem path.
session=""
cwd=""
saved_ts=""

# `display -p -t` needs a pane target and returns empty fields for a bare
# session name, so session-scoped formats are read via `list-sessions -f`
# with an exact-name filter instead.
session_info() {
  tmux list-sessions -f "#{==:#{session_name},$session}" -F "$1" 2>/dev/null
}

if tmux has-session -t "=$selection" 2>/dev/null; then
  session="$selection"
  cwd="$(session_info '#{session_path}')"
elif [ -f "$state_file" ]; then
  cwd="$(awk -F '\t' -v n="$selection" '$1 == n {print $2; exit}' "$state_file")"
  # Third column = first-saved epoch (see save.sh). Empty for entries that
  # pre-date the epoch field.
  saved_ts="$(awk -F '\t' -v n="$selection" '$1 == n {print $3; exit}' "$state_file")"
fi

if [ -z "$cwd" ]; then
  path="${selection/#\~/$HOME}"
  [ -d "$path" ] && cwd="$path"
fi

# --- Session basics ---------------------------------------------------------
printf '%s%s%s\n' "$bold$cyan" "$selection" "$reset"

fmt_ts() { date -r "$1" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?'; }

if [ -n "$session" ]; then
  created="$(session_info '#{session_created}')"
  attached_at="$(session_info '#{session_last_attached}')"
  activity="$(session_info '#{session_activity}')"
  clients="$(session_info '#{session_attached}')"

  label 'status' "${green}running${reset} (${clients} client(s) attached)"
  label 'created' "$(fmt_ts "$created")"
  [ "${attached_at:-0}" -gt 0 ] 2>/dev/null \
    && label 'attached' "$(fmt_ts "$attached_at")"
  # session_activity = last time any pane in the session produced output.
  [ "${activity:-0}" -gt 0 ] 2>/dev/null \
    && label 'activity' "$(fmt_ts "$activity")"
else
  label 'status' "${dim}not running (will be created)${reset}"
  # First-saved epoch from sessions.list — the closest thing a not-running
  # session has to a creation date.
  [ -n "$saved_ts" ] && label 'saved' "$(fmt_ts "$saved_ts")"
fi
[ -n "$cwd" ] && label 'path' "${cwd/#$HOME/\~}"

# --- Git state --------------------------------------------------------------
if [ -n "$cwd" ] && [ -d "$cwd" ] \
  && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  section ' git'

  branch="$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"
  label 'branch' "${yellow}${branch}${reset}"

  dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$dirty" -gt 0 ]; then
    label 'dirty' "${red}${dirty} file(s)${reset}"
  else
    label 'dirty' "${green}clean${reset}"
  fi

  # Ahead/behind vs upstream; skipped silently when no upstream is set.
  read -r behind ahead < <(git -C "$cwd" rev-list --left-right --count \
    '@{upstream}...HEAD' 2>/dev/null) || true
  [ -n "${ahead:-}" ] && label 'upstream' "↑${ahead} ↓${behind}"

  last="$(git -C "$cwd" log -1 --format='%s %C(black bold)(%cr)%Creset' \
    --color=always 2>/dev/null)"
  [ -n "$last" ] && label 'commit' "$last"
fi

# --- Windows + running commands (live sessions only) ------------------------
if [ -n "$session" ]; then
  section ' windows'
  tmux list-windows -t "=$session" \
    -F '#{window_index}|#{window_name}|#{window_panes}|#{window_active}' \
    | while IFS='|' read -r idx name panes active; do
        marker=' '
        [ "$active" = 1 ] && marker="${green}*${reset}"
        printf '  %s %s%s:%s %s %s(%s pane(s))%s\n' \
          "$marker" "$cyan" "$idx" "$reset" "$name" "$dim" "$panes" "$reset"
      done

  section ' running'
  tmux list-panes -s -t "=$session" \
    -F '#{window_index}.#{pane_index}|#{pane_current_command}|#{pane_current_path}' \
    | while IFS='|' read -r pane cmd ppath; do
        printf '  %s%-6s%s %-12s %s%s%s\n' \
          "$cyan" "$pane" "$reset" "$cmd" "$dim" "${ppath/#$HOME/\~}" "$reset"
      done
fi

exit 0
