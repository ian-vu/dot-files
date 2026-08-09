#!/usr/bin/env sh
# Re-source hooks.conf AFTER the opensessions plugin has finished installing
# its tmux hooks, so our user hooks coexist with the plugin on a fresh server.
#
# Why this is needed: on a fresh `tmux` start, hooks.conf is sourced BEFORE the
# opensessions plugin initializes (TPM runs at the end of tmux.conf, and the
# plugin's server starts in the background). The plugin registers its hooks with
# `set-hook -g name cmd`, which REPLACES the whole hook array, wiping the user
# hooks we appended during the initial hooks.conf source. Without this script
# they only come back on the first manual `tmux source-file`.
#
# How it works: we poll `tmux show-hooks -g` for the plugin's last-installed hook
# marker (`/pane-layout-changed` on after-resize-window - the final set_global_hook
# call in the plugin's install_hooks). Once present, the plugin is done, so we
# re-source hooks.conf; our hooks use dedup+append and land after the plugin's
# entries. A timeout falls back to sourcing anyway so user hooks still register
# if the plugin is absent/disabled (in which case nothing clobbers them anyway).
#
# Invoked backgrounded (`run-shell -b`) from the end of tmux.conf, after TPM.

set -u

hooks_file="${1:-$HOME/.config/tmux/hooks.conf}"
# 0.5s poll interval; ~20s ceiling before we give up waiting and just source.
max_polls=40
marker='/pane-layout-changed'

i=0
while [ "$i" -lt "$max_polls" ]; do
  if tmux show-hooks -g 2>/dev/null | grep -F -q "$marker"; then
    break
  fi
  i=$((i + 1))
  sleep 0.5
done

tmux source-file "$hooks_file" >/dev/null 2>&1 || true
