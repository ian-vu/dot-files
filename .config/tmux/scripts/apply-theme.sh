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
tmux set -g copy-mode-position-style "fg=${THEME_MODE_FG},bg=${THEME_MODE_BG}"
tmux set -g status-style "fg=${THEME_FG},bg=${THEME_BG_STATUS}"
tmux set -g message-style "fg=${THEME_MSG_FG},bg=${THEME_MSG_BG}"
tmux set -g message-command-style "fg=${THEME_MSG_FG},bg=${THEME_MSG_BG}"
tmux set -g pane-border-style "fg=${THEME_BORDER}"
# Recolor the active pane border to the theme mode color (orange) while the
# active pane is in copy mode, and the normal active border color (blue for
# tokyonight) otherwise. tmux expands the #{?...} format at render time per
# pane, so this automatically tracks copy-mode enter/exit and pane/window/
# session switches without any hooks. Scope is copy-mode only (not view-mode
# or other modes) to match the request.
tmux set -g pane-active-border-style "fg=#{?#{==:#{pane_mode},copy-mode},${THEME_MODE_BG},${THEME_BORDER_ACT}}"
tmux setw -g window-status-style "${THEME_WIN_STYLE}"
tmux setw -g window-status-activity-style "${THEME_WIN_ACT_STYLE}"

# Match popup and context-menu borders to the active theme.
tmux set -g popup-border-lines rounded
tmux set -g popup-border-style "fg=${THEME_BORDER_ACT}"
tmux set -g menu-border-lines rounded
tmux set -g menu-border-style "fg=${THEME_BORDER}"
tmux set -g menu-selected-style "fg=${THEME_ACCENT_FG},bg=${THEME_ACCENT},bold"

# Prefix highlight plugin
tmux set -g @prefix_highlight_output_prefix "#[fg=${THEME_HIGHLIGHT}]#[bg=${THEME_BG}]#[fg=${THEME_BG}]#[bg=${THEME_HIGHLIGHT}]"
tmux set -g @prefix_highlight_output_suffix ""

# Status left
# Offset the window list past the tmux-sidebar pane so it lines up with the
# main pane instead of being covered by the sidebar. Width authority is the
# @tmux_sidebar_width tmux option (seeded here or by sidebar-ensure.sh); fall
# back to the width in ~/.config/tmux-sidebar/config.json, then 32. The dynamic
# padding format reads the option on every status redraw, so interactive width
# changes take effect without reapplying the theme. A thin ┃ in the pane-border
# color is drawn where the sidebar/main pane split sits. The padding only shows
# when the current window contains a pane titled "tmux-sidebar".
SIDEBAR_WIDTH=$(tmux show -gqv @tmux_sidebar_width 2>/dev/null)
if [ -z "$SIDEBAR_WIDTH" ]; then
  SIDEBAR_WIDTH=$(jq -r '.width // 32' "$HOME/.config/tmux-sidebar/config.json" 2>/dev/null || echo 32)
  tmux set -g @tmux_sidebar_width "$SIDEBAR_WIDTH"
fi
tmux set -g status-left "#[bg=${THEME_BG},fg=${THEME_LEFT_FG},nobold,noitalics,nounderscore]#{?#{m:*tmux-sidebar*,#{P:#{pane_title}\|}},#{p-#{@tmux_sidebar_width}:x}#[fg=${THEME_BORDER}]┃#[fg=${THEME_LEFT_FG}],}"

# Leave idle shell windows blank instead of showing the bare "zsh" command
# name. Real programs (nvim, git, ...) still name the window via #W. A manually
# renamed window (prefix-,, or the claude/codex aliases in .zshrc) keeps its
# custom name even while a zsh pane is focused, so only blank when the window
# name is still the auto-generated "zsh".
WINNAME='#{?#{==:#{pane_current_command},zsh},#{?#{==:#{window_name},zsh},,#W},#W}'
# Resolves to "1" exactly when WINNAME is blank (idle zsh whose window name is
# still the auto-generated "zsh"), else empty. Used to gate the  divider and
# its surrounding padding out of the tab so an unnamed window shows just "#I"
# instead of "#I  " with a dangling divider.
NAMEBLANK='#{?#{==:#{pane_current_command},zsh},#{?#{==:#{window_name},zsh},1,},}'

# Window status formats
# Window 1 sits flush against the sidebar's ┃ bar, so its pill drops the
# leading  arrow; windows 2+ keep it. The leading glyph is wrapped in a
# window_index conditional (style directives stay outside the conditional
# because commas inside #[] would break #{?,,} parsing).
LEAD_CUR="#[bg=${THEME_ACCENT},fg=${THEME_BG},nobold,noitalics,nounderscore]#{?#{==:#{window_index},1},,}"
LEAD_SEC="#[bg=${THEME_SEC_BG},fg=${THEME_BG},noitalics]#{?#{==:#{window_index},1},,}"
tmux setw -g window-status-current-format "${LEAD_CUR}#[bg=${THEME_ACCENT},fg=${THEME_ACCENT_FG}] #I #{?${NAMEBLANK},,#[bg=${THEME_ACCENT}]#[fg=${THEME_ACCENT_FG}]#[bold] ${WINNAME}#{?window_zoomed_flag,*Z,} }#[bg=${THEME_BG},fg=${THEME_ACCENT},nobold,noitalics,nounderscore]"
tmux setw -g window-status-format "${LEAD_SEC}#[bg=${THEME_SEC_BG},fg=${THEME_SEC_FG}] #I #{?${NAMEBLANK},, ${WINNAME} }#[bg=${THEME_BG},fg=${THEME_SEC_BG},noitalics]"

# Status right
tmux set -g status-right "#[bg=${THEME_BG},fg=${THEME_SEC_BG} nobold, nounderscore, noitalics]#[bg=${THEME_SEC_BG},fg=${THEME_SEC_FG}]#(~/.config/tmux/scripts/cpu.sh)#[fg=${THEME_SEC_FG}]#(~/.config/tmux/scripts/mem.sh)#[fg=${THEME_SEC_FG}]#(~/.config/tmux/scripts/battery.sh)#[fg=${THEME_SEC_FG}] %I:%M %p #[bg=${THEME_SEC_BG},fg=${THEME_ACCENT},nobold,noitalics,nounderscore]#[bg=${THEME_ACCENT},fg=${THEME_ACCENT_FG},nobold,noitalics,nounderscore] #(~/.config/tmux/scripts/format-session.sh #{session_name}) "

# Theme-specific extras (e.g. gruvbox clock color, bell style)
if type theme_extras &>/dev/null; then
  theme_extras
fi
