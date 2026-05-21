# Pi

This repo stores Pi configuration under the same paths used in `$HOME`, but a few files are intentionally repo-local developer support files rather than runtime Pi config.

## Useful upstream docs

- [Pi docs](https://pi.dev/docs/latest)
- [Settings](https://pi.dev/docs/latest/settings) — global and project `settings.json` options.
- [Extensions](https://pi.dev/docs/latest/extensions) — extension locations, runtime loading, custom tools, and events.
- [Packages](https://pi.dev/docs/latest/packages) — installing and sharing Pi packages.
- [Models](https://pi.dev/docs/latest/models) — custom provider/model configuration.
- [Keybindings](https://pi.dev/docs/latest/keybindings) — interactive shortcut customization.

## MCP servers

Global shared MCP configuration lives in `.config/mcp/mcp.json`, which stows to `~/.config/mcp/mcp.json` so Pi's `pi-mcp-adapter` can discover it without Pi-specific imports.

Linear and Notion use their hosted Streamable HTTP endpoints with OAuth because that avoids local MCP packages/API keys and lets each service manage server updates.

After adding or changing MCP servers in an already-running Pi session, run `/reload` or restart Pi. For OAuth servers such as Linear or Notion, run `/mcp-auth <server>` if `autoAuth` does not prompt automatically.

## User-private local context

The global Pi extension `.pi/agent/extensions/local-context.ts` lets each checkout provide machine/user-specific context without editing or committing the repo's shared `AGENTS.md`.

Create this file inside any repo where local context is needed:

```sh
mkdir -p .pi
$EDITOR .pi/LOCAL_CONTEXT.md
```

It is ignored globally via `~/.gitignore_global`, so it should not appear in `git status` for any repo using this dotfiles Git config. If you are on a machine without that global ignore, keep it local to the checkout by adding it to the repo-local Git exclude file instead of `.gitignore`:

```sh
echo ".pi/LOCAL_CONTEXT.md" >> .git/info/exclude
```

Example content:

```md
# Local context

- When running Python commands, tests, pytest, tox, or nox, prefix with `LOCAL_ENV=1`.
- Reason: this machine uses `LOCAL_ENV=1` to load local `.env` files.
```

The extension discovers `.pi/LOCAL_CONTEXT.md` from the current git repo root down to the current working directory and appends those notes after Pi's normal context, including `AGENTS.md`. This ordering is intentional so local machine context can clarify how commands should be run without changing shared project instructions.

After creating or editing a local context file in an already-running Pi session, run `/reload` or restart Pi.

## Extension LSP project

`.pi/agent/extensions/tsconfig.json` exists for Neovim/TypeScript language-server support while editing Pi extensions in this repo. Pi itself loads TypeScript extensions with `jiti`, so it does not need this file to run extensions.

The config deliberately sets modern Node/ESM options because Pi and its dependencies publish modern type definitions:

- `target: "ES2022"` avoids false errors from modern `.d.ts` syntax.
- `module` and `moduleResolution: "NodeNext"` match Node ESM and this directory's `"type": "module"` package.
- `skipLibCheck: true` prevents dependency declaration-file noise from drowning out extension diagnostics.
- `types: ["node"]` gives extensions Node globals without pulling in unrelated ambient types.
- `noEmit: true` keeps TypeScript checks from writing generated files into the dotfiles repo.

The adjacent `package.json`, lockfile, `node_modules/`, and `tsconfig.json` are ignored by stow on purpose: they support local editor/type-checking only. Runtime extension imports should still be valid from Pi's actual extension loading environment.

## Package runtime state

Pi package installs live under `~/.pi/agent/npm/` and `~/.pi/agent/git/`. These are runtime caches, not dotfiles, and must not be symlinked into this repo. If Pi reports an extension under `~/.pi/agent/npm/...` but the error mentions `~/dot-files/.pi/agent/npm/...`, then Pi is using the repo as its agent directory or stow has exposed package runtime state.

Troubleshooting:

```sh
# These should normally be empty/unset.
echo "$PI_CODING_AGENT_DIR"
echo "$PI_PACKAGE_DIR"

# This should be a real directory, not a symlink into ~/dot-files.
ls -ld ~/.pi/agent/npm ~/.pi/agent/npm/node_modules
readlink ~/.pi/agent/npm ~/.pi/agent/npm/node_modules 2>/dev/null

# Repair symlinks from the repo root after changing stow ignores.
stow --no-folding .

# Reinstall package resources if a package cache was removed or corrupted.
pi update npm:pi-web-access
```
