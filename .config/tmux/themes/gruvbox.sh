#!/usr/bin/env bash
# Gruvbox dark (medium) — color definitions for apply-theme.sh

THEME_BG="colour235"
THEME_BG_STATUS="default"  # transparent status bar
THEME_FG="colour223"
THEME_ACCENT="colour244"
THEME_ACCENT_FG="colour233"
THEME_SEC_BG="colour239"
THEME_SEC_FG="colour246"
THEME_BORDER="colour235"
THEME_BORDER_ACT="colour250"
THEME_MODE_FG="colour214"
THEME_MODE_BG="colour239"
THEME_MSG_FG="colour223"
THEME_MSG_BG="colour239"
THEME_HIGHLIGHT="colour214"
THEME_LEFT_FG="colour241"
THEME_WIN_STYLE="bg=colour214,fg=colour235"
THEME_WIN_ACT_STYLE="bg=colour235,fg=colour248"

theme_extras() {
  tmux set -g display-panes-active-colour "colour250"
  tmux set -g display-panes-colour "colour235"
  tmux setw -g clock-mode-colour "colour109"
  tmux setw -g window-status-bell-style "bg=colour167,fg=colour235"
  tmux setw -g window-status-current-style "bg=red,fg=colour235"
}
