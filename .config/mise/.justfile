# Global justfile. Invoke from anywhere with `just -g <recipe>`.
# List all recipes with `just -g --list`.

# install or update a global mise tool to latest — e.g. `just -g up npm:@tokscale/cli`
up package:
    mise use -g {{ package }}@latest

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
