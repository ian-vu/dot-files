#!/usr/bin/env bash
# ============================================================================
# scripts/sessions/picker.sh
# ============================================================================
# Purpose:
#   Interactive fzf-tmux popup for switching to / creating tmux sessions.
#   The single UI for browsing four overlapping sources of "session targets":
#   the persistent saved list, the live tmux sessions, zoxide directories,
#   and a generic find of dirs under $HOME.
#
# Called from:
#   - plugin_config/sessions.conf (`prefix + t` keybinding)
#   - bin/t                       (no-arg invocation)
#
# Source views (toggled by Ctrl-*):
#   default / Ctrl-t  ->  saved list   (persistent, MRU-ordered)
#   Ctrl-a            ->  active       (live tmux sessions, MRU by attach)
#   Ctrl-d            ->  zoxide dirs  (frecent directories)
#   Ctrl-f            ->  fd dirs      (under $HOME, max depth 2)
#
# Action bindings:
#   Ctrl-x   kill highlighted session (the session-closed hook removes it
#            from the saved list — single source of truth for removal).
#   Ctrl-s   re-seed the saved list from currently-live tmux sessions.
#   Enter    hand the selection to connect.sh.
# ============================================================================

set -u

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/sessions.list"
current_session="$(tmux display -p '#S' 2>/dev/null || echo '')"

# Dismiss any open float popup so it doesn't sit on top of / behind ours.
tmux_close_float >/dev/null 2>&1 || true

# Source-list helpers used to populate the INITIAL picker view.
# (The Ctrl-* reload bindings can't reuse these — see "Inline commands"
# below for why — so they exist mainly to drive list_default.)

list_saved() {
  # Hide the current session: switching to yourself is a no-op, and it just
  # clutters the picker.
  [ -f "$state_file" ] || return 0
  awk -F '\t' -v cur="$current_session" '$1 != cur {print $1}' "$state_file"
}

list_active() {
  # MRU by `#{session_last_attached}` (epoch). Never-attached sessions
  # report 0 and sort to the bottom. `|` is a safer separator than TAB
  # here because session names can contain spaces but not `|` in practice.
  tmux list-sessions -F '#{session_last_attached}|#{session_name}' 2>/dev/null \
    | awk -F '|' -v cur="$current_session" '$2 != cur && $2 !~ /float/' \
    | sort -t '|' -k1,1 -rn \
    | awk -F '|' '{print $2}'
}

list_default() {
  # Saved list when populated; otherwise fall back to live sessions so a
  # first-time / freshly-synced picker is never empty.
  local out
  out="$(list_saved)"
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
  else
    list_active
  fi
}

# Inline command strings for the fzf reload bindings.
# fzf runs reload commands via `$SHELL -c "..."`, which is zsh in this setup.
# zsh can't see bash-exported functions, so the bindings can't call the
# helpers above directly. We expand $state_file / $current_session here, in
# the parent bash, so the bindings hand fzf self-contained shell snippets.

cmd_saved="awk -F '\t' -v cur=\"$current_session\" '\$1 != cur {print \$1}' \"$state_file\""
cmd_active="tmux list-sessions -F '#{session_last_attached}|#{session_name}' 2>/dev/null | awk -F '|' -v cur=\"$current_session\" '\$2 != cur && \$2 !~ /float/' | sort -t '|' -k1,1 -rn | awk -F '|' '{print \$2}'"
cmd_zoxide="command -v zoxide >/dev/null 2>&1 && zoxide query -l 2>/dev/null"
cmd_find="command -v fd >/dev/null 2>&1 && fd -H -d 2 -t d -E .Trash . \"\$HOME\""

# Picker.
# `--no-sort` preserves source ordering so the MRU semantics of saved/active
# views aren't shuffled by fzf.
# Ctrl-x has an ~80ms sleep before reload because the session-closed hook
# (which rewrites sessions.list) runs via tmux's async `run-shell`; without
# the sleep we'd sometimes re-read the file before the hook has updated it.

selection="$(list_default | fzf-tmux \
  -p 100,40% \
  --layout reverse \
  --info right \
  --keep-right \
  --pointer ' ➜' \
  --color "gutter:#222436,border:#ff966c,label:#ff966c" \
  --no-sort \
  --border-label ' Tmux Sessions ' \
  --prompt '  ' \
  --bind 'tab:down,btab:up' \
  --bind "ctrl-t:change-prompt(  )+reload($cmd_saved)" \
  --bind "ctrl-a:change-prompt(⚡ )+reload($cmd_active)" \
  --bind "ctrl-d:change-prompt(📁 )+reload($cmd_zoxide)" \
  --bind "ctrl-f:change-prompt(🔎 )+reload($cmd_find)" \
  --bind "ctrl-x:execute-silent(tmux kill-session -t {} 2>/dev/null; sleep 0.08)+change-prompt(  )+reload($cmd_saved)" \
  --bind "ctrl-s:execute-silent($HOME/.config/tmux/scripts/sessions/sync.sh >/dev/null 2>&1)+change-prompt(  )+reload($cmd_saved)" \
  --header '  C-t Saved | C-a Active | C-d Zoxide | C-f Find | C-s Sync | C-x Kill' \
)"

# Empty selection = Esc / Ctrl-c.
[ -z "$selection" ] && exit 0

"$HOME/.config/tmux/scripts/sessions/connect.sh" "$selection"
