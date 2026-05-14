# Global justfile. Invoke from anywhere with `just -g <recipe>`.
# List all recipes with `just -g --list`.

# install or update a global mise tool to latest — e.g. `just -g up npm:@tokscale/cli`
up package:
    mise use -g {{ package }}@latest

# update an installed mise tool to latest by fuzzy name — e.g. `just -g update codex`
update name:
    #!/usr/bin/env bash
    # Resolve a fuzzy name (e.g. "codex") to the full mise tool key (e.g. "npm:@openai/codex")
    # by case-insensitive substring match against currently installed tools.
    set -euo pipefail
    query={{ quote(name) }}
    matches=$(mise ls -J | jq -r 'keys[]' | grep -iF -- "$query" || true)
    if [ -z "$matches" ]; then
        echo "No installed mise tool matches '$query'" >&2
        exit 1
    fi
    count=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
    if [ "$count" -gt 1 ]; then
        echo "Multiple tools match '$query':" >&2
        printf '  %s\n' $matches >&2
        exit 1
    fi
    mise use -g "${matches}@latest"

# list all installed mise tools and active versions
ls:
    mise ls

# show which installed mise tools have newer versions available
outdated:
    mise outdated

# preview which unused mise tool versions would be deleted (safe, no changes)
prune-dry:
    mise prune --dry-run

# delete unused mise tool versions — run `prune-dry` first to preview
prune:
    mise prune

# uninstall one specific mise tool version — e.g. `just -g uninstall npm:@tokscale/cli@1.0.0`
uninstall tool:
    mise uninstall {{ tool }}

# remove a mise tool entirely (config + disk) — e.g. `just -g remove npm:@tokscale/cli`
remove tool:
    mise rm -g {{ tool }}
