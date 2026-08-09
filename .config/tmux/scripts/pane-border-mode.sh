#!/usr/bin/env sh
# Recolor the active pane border to reflect whether the active pane is in
# copy mode: orange (the theme mode color) while in copy mode, and the
# theme's normal active border color (blue for tokyonight) otherwise.
#
# tmux has no per-pane border color, but only the active pane uses
# pane-active-border-style, so recoloring that single global window option is
# enough. The script always queries the CURRENT active pane (not the pane
# that triggered the hook) so a background pane changing mode cannot desync
# the visible border. Non-focused windows are recolored on demand when they
# regain focus via the after-select-window / client-session-changed hooks.
#
# Called from pane-mode-changed, after-select-pane, after-select-window, and
# client-session-changed hooks (see hooks.conf). Scope is copy-mode only, not
# view-mode/tree-mode, to match the user request.

# Colors are published by apply-theme.sh as user options so this tracks the
# active theme without re-sourcing the theme file.
mode_bg=$(tmux show-option -gqv @theme_mode_bg 2>/dev/null)
border_act=$(tmux show-option -gqv @theme_border_act 2>/dev/null)
[ -z "$mode_bg" ] && mode_bg="#ff9e64"
[ -z "$border_act" ] && border_act="#82aaff"

# pane_mode names the current mode (copy-mode, view-mode, tree-mode, ...).
if [ "$(tmux display -p '#{pane_mode}' 2>/dev/null)" = "copy-mode" ]; then
  tmux set -g pane-active-border-style "fg=$mode_bg"
else
  tmux set -g pane-active-border-style "fg=$border_act"
fi
