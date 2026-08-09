# meeting-sync recipes. Invoke as `just tools meeting-sync <recipe>`.
# source_directory() keeps these cwd-independent (matches .homebrew/.justfile).

default:
    @just --list

# Phase 1: probe the Notion API and print the meeting notes it returns.
probe:
    {{ source_directory() }}/bin/meeting-sync --probe

# Run a sync now.
run:
    {{ source_directory() }}/bin/meeting-sync

# Refresh the local token cache from 1Password (run after creating the item in
# 1Password and setting `notionTokenRef` in config.json, or when the cache is stale).
# Requires the `op` CLI to be signed in.
refresh-token:
    {{ source_directory() }}/bin/meeting-sync --check-token

# Deploy the launchd agent (symlinks the plist into ~/Library/LaunchAgents).
install:
    cd {{ source_directory() }} && stow --no-folding --dir deploy \
        --target "$HOME/Library/LaunchAgents" launchagents
    launchctl load -w ~/Library/LaunchAgents/com.ivu.meeting-sync.plist

# Remove the launchd agent.
uninstall:
    launchctl unload -w ~/Library/LaunchAgents/com.ivu.meeting-sync.plist
    cd {{ source_directory() }} && stow -D --no-folding --dir deploy \
        --target "$HOME/Library/LaunchAgents" launchagents
