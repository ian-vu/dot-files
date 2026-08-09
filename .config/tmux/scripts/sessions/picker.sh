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
#   default / Ctrl-t  ->  saved + live merged (see scripts/sessions/list.sh)
#   Ctrl-a            ->  active       (live tmux sessions, MRU by attach)
#   Ctrl-d            ->  zoxide dirs  (frecent directories)
#   Ctrl-f            ->  fd dirs      (under $HOME, max depth 2)
#
# Action bindings:
#   Ctrl-x   kill highlighted session (if live) and drop it from the saved
#            list. The explicit remove covers stale saved entries whose tmux
#            session is already gone, so no session-closed hook will fire.
#   Ctrl-s   re-seed the saved list from currently-live tmux sessions.
#   Ctrl-p   toggle a right-split preview with session info (created/attached
#            time, cwd, git branch/dirty/upstream, windows, running commands).
#            Hidden by default to keep the picker compact; see preview.sh.
#   Enter    hand the selection to connect.sh.
# ============================================================================

set -u

current_session="$(tmux display -p '#S' 2>/dev/null || echo '')"

# Dismiss any open float popup so it doesn't sit on top of / behind ours.
tmux_close_float >/dev/null 2>&1 || true

# Inline command strings for the fzf reload bindings.
# fzf runs reload commands via `$SHELL -c "..."`. The default/saved view is
# extracted into list.sh so it can be reused by the Ctrl-t binding. The
# remaining commands stay inline because they're one-liners and don't share
# logic with anything else.

cmd_default_raw="$HOME/.config/tmux/scripts/sessions/list.sh"

# Dim the repo/wt/ prefix for worktree sessions so the branch/worktree name is
# the visual anchor. fzf --ansi strips these escape codes from the accepted item.
format_sessions_for_fzf() {
  perl -pe 's{^(.*/wt/)(.+)$}{\e[90m$1\e[0m$2}'
}
format_sessions_cmd='perl -pe '"'"'s{^(.*/wt/)(.+)$}{\e[90m$1\e[0m$2}'"'"''

cmd_default="$cmd_default_raw | $format_sessions_cmd"
cmd_active="tmux list-sessions -F '#{session_last_attached}|#{session_name}' 2>/dev/null | awk -F '|' -v cur=\"$current_session\" '\$2 != cur && \$2 !~ /float/' | sort -t '|' -k1,1 -rn | awk -F '|' '{print \$2}' | $format_sessions_cmd"
cmd_zoxide="command -v zoxide >/dev/null 2>&1 && zoxide query -l 2>/dev/null"
cmd_find="command -v fd >/dev/null 2>&1 && fd -H -d 2 -t d -E .Trash . \"\$HOME\""

# Picker.
# `--no-sort` preserves source ordering so the MRU semantics of saved/active
# views aren't shuffled by fzf.
# Ctrl-x has an ~80ms sleep before reload because the session-closed hook
# (which rewrites sessions.list) runs via tmux's async `run-shell`; without
# the sleep we'd sometimes re-read the file before the hook or explicit
# remove has updated it.

popup_width=100
session_trunc="${current_session:0:35}"
left_label=" Tmux Session"
right_label="[$session_trunc] "
gap=$((popup_width - 4 - ${#left_label} - ${#right_label}))
fill=$(printf '─%.0s' $(seq 1 "$gap"))
border_label="${left_label}${fill}${right_label}"

selection="$("$cmd_default_raw" | format_sessions_for_fzf | fzf-tmux \
  -p ${popup_width},40% \
  --layout reverse \
  --info right \
  --keep-right \
  --ansi \
  --pointer ' ➜' \
  --color "gutter:#222436,border:#ff966c,label:#ff966c" \
  --no-sort \
  `# --query "'" seeds the fzf prompt with the exact-match prefix (https://junegunn.github.io/fzf/search-syntax/)` \
  --query "'" \
  --border-label "$border_label" \
  --border-label-pos 0 \
  --prompt '  ' \
  `# Preview starts hidden; Ctrl-p toggles it. {} is the plain selection` \
  `# (fzf --ansi strips colors before substitution), which preview.sh` \
  `# resolves the same way connect.sh does.` \
  --preview "$HOME/.config/tmux/scripts/sessions/preview.sh {}" \
  --preview-window 'right,55%,border-left,hidden' \
  --bind 'ctrl-p:toggle-preview' \
  --bind 'tab:down,btab:up' \
  --bind "ctrl-t:change-prompt(  )+reload($cmd_default)" \
  --bind "ctrl-a:change-prompt(⚡ )+reload($cmd_active)" \
  --bind "ctrl-d:change-prompt(📁 )+reload($cmd_zoxide)" \
  --bind "ctrl-f:change-prompt(🔎 )+reload($cmd_find)" \
  --bind "ctrl-x:execute-silent(tmux kill-session -t {} 2>/dev/null; $HOME/.config/tmux/scripts/sessions/remove.sh {} >/dev/null 2>&1; sleep 0.08)+change-prompt(  )+reload($cmd_default)" \
  --bind "ctrl-s:execute-silent($HOME/.config/tmux/scripts/sessions/sync.sh >/dev/null 2>&1)+change-prompt(  )+reload($cmd_default)" \
  --header '  C-t Saved | C-a Active | C-d Zoxide | C-f Find | C-s Sync | C-x Kill | C-p Info' \
)"

# Empty selection = Esc / Ctrl-c.
[ -z "$selection" ] && exit 0

"$HOME/.config/tmux/scripts/sessions/connect.sh" "$selection"
