#!/usr/bin/env bash
# Shared tmux theme layout — sources a color variables file and applies the theme.
# Usage: apply-theme.sh <theme-file.sh>
# Each theme file defines THEME_* color variables and an optional theme_extras() function.

source "$1"

# Status bar layout
tmux set -g status "on"
tmux set -g status-justify "left"
tmux set -g status-left-length "100"
tmux set -g status-right-length "100"
tmux set -g status-left-style "NONE"
tmux set -g status-right-style "NONE"
tmux setw -g window-status-separator ""

# Undercurl support (default-terminal is set in tmux.conf; do not stomp it here —
# run-shell on tmux 3.6+ exports TERM=dumb, which breaks Starship and colors)
tmux set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
tmux set -as terminal-overrides ',*:Setulc=\E[58::2::::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

# Colors
tmux set -g mode-style "fg=${THEME_MODE_FG},bg=${THEME_MODE_BG}"
tmux set -g status-style "fg=${THEME_FG},bg=${THEME_BG_STATUS}"
tmux set -g message-style "fg=${THEME_MSG_FG},bg=${THEME_MSG_BG}"
tmux set -g message-command-style "fg=${THEME_MSG_FG},bg=${THEME_MSG_BG}"
tmux set -g pane-border-style "fg=${THEME_BORDER}"
tmux set -g pane-active-border-style "fg=${THEME_BORDER_ACT}"
tmux setw -g window-status-style "${THEME_WIN_STYLE}"
tmux setw -g window-status-activity-style "${THEME_WIN_ACT_STYLE}"

# Prefix highlight plugin
tmux set -g @prefix_highlight_output_prefix "#[fg=${THEME_HIGHLIGHT}]#[bg=${THEME_BG}]#[fg=${THEME_BG}]#[bg=${THEME_HIGHLIGHT}]"
tmux set -g @prefix_highlight_output_suffix ""

# Status left
tmux set -g status-left "#[bg=${THEME_BG},fg=${THEME_LEFT_FG},nobold,noitalics,nounderscore]"

# Window status formats
tmux setw -g window-status-current-format "#[bg=${THEME_ACCENT},fg=${THEME_BG},nobold,noitalics,nounderscore]#[bg=${THEME_ACCENT},fg=${THEME_ACCENT_FG}] #I #[bg=${THEME_ACCENT},fg=${THEME_ACCENT_FG},bold] #W#{?window_zoomed_flag,*Z,} #[bg=${THEME_BG},fg=${THEME_ACCENT},nobold,noitalics,nounderscore]"
tmux setw -g window-status-format "#[bg=${THEME_SEC_BG},fg=${THEME_BG},noitalics]#[bg=${THEME_SEC_BG},fg=${THEME_SEC_FG}] #I  #W #[bg=${THEME_BG},fg=${THEME_SEC_BG},noitalics]"

# Status right
tmux set -g status-right "#[bg=${THEME_BG},fg=${THEME_SEC_BG} nobold, nounderscore, noitalics]#[bg=${THEME_SEC_BG},fg=${THEME_SEC_FG}] #(~/.config/tmux/scripts/cpu.sh)#[fg=${THEME_SEC_FG}]  #(~/.config/tmux/scripts/mem.sh)#[fg=${THEME_SEC_FG}]  #(~/.config/tmux/scripts/battery.sh)#[fg=${THEME_SEC_FG}]  %I:%M %p  󰘬 #(~/.config/tmux/scripts/git-branch.sh #{pane_current_path}) #[bg=${THEME_SEC_BG},fg=${THEME_ACCENT},nobold,noitalics,nounderscore]#[bg=${THEME_ACCENT},fg=${THEME_ACCENT_FG},nobold,noitalics,nounderscore] #(~/.config/tmux/scripts/format-session.sh #{session_name}) "

# Theme-specific extras (e.g. gruvbox clock color, bell style)
if type theme_extras &>/dev/null; then
  theme_extras
fi
