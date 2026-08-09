#!/usr/bin/env bash
# TokyoNight Moon — color definitions for apply-theme.sh

# Match the terminal background (#222436, TokyoNight Moon "bg") so the status
# bar blends in instead of using the darker "bg_dark" (#1e2030).
THEME_BG="#222436"
THEME_BG_STATUS="#222436"
THEME_FG="#82aaff"
THEME_ACCENT="#82aaff"
THEME_ACCENT_FG="#1b1d2b"
THEME_SEC_BG="#3b4261"
THEME_SEC_FG="#828bb8"
THEME_BORDER="#3b4261"
# Keep the active pane border on the TokyoNight accent color.
THEME_BORDER_ACT="#82aaff"
THEME_MODE_FG="#1b1d2b"
THEME_MODE_BG="#ff9e64"
THEME_MSG_FG="#1b1d2b"
THEME_MSG_BG="#ff9e64"
THEME_HIGHLIGHT="#ffc777"
THEME_LEFT_FG="#3b4261"
THEME_WIN_STYLE="NONE,fg=#828bb8,bg=#222436"
# Keep stale or externally-set activity flags from underlining window tabs.
THEME_WIN_ACT_STYLE="NONE,fg=#828bb8,bg=#222436"

theme_extras() {
  # Undercurl (default-terminal is set in tmux.conf; do not stomp it from a
  # run-shell context — tmux 3.6 sets TERM=dumb there, which kills colors)
  tmux set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'                                                          # undercurl support
  tmux set -as terminal-overrides ',*:Setulc=\E[58::2::::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m' # underscore colours - needs tmux-3.0
}
