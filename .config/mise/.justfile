# Global justfile. Invoke from anywhere with `just -g <recipe>`.
# List all recipes with `just -g --list`.

# install a global mise-managed tool; defaults to latest, or pass a version — e.g. `just -g install npm:@tokscale/cli` or `just -g install npm:@tokscale/cli 1.2.3`
install package version='latest':
    mise use -g {{ package }}@{{ version }}

# update a mise-managed tool while preserving configured version ranges — e.g. `just -g update npm:@tokscale/cli` or `just -g update pi`
update package:
    mise upgrade {{ package }}

# update pi only
update-pi:
    mise install -q npm:@earendil-works/pi-coding-agent@latest
    pi update --self

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
