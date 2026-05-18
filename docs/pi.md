# Pi

This repo stores Pi configuration under the same paths used in `$HOME`, but a few files are intentionally repo-local developer support files rather than runtime Pi config.

## Useful upstream docs

- [Pi docs](https://pi.dev/docs/latest)
- [Settings](https://pi.dev/docs/latest/settings) — global and project `settings.json` options.
- [Extensions](https://pi.dev/docs/latest/extensions) — extension locations, runtime loading, custom tools, and events.
- [Packages](https://pi.dev/docs/latest/packages) — installing and sharing Pi packages.
- [Models](https://pi.dev/docs/latest/models) — custom provider/model configuration.
- [Keybindings](https://pi.dev/docs/latest/keybindings) — interactive shortcut customization.

## Extension LSP project

`.pi/agent/extensions/tsconfig.json` exists for Neovim/TypeScript language-server support while editing Pi extensions in this repo. Pi itself loads TypeScript extensions with `jiti`, so it does not need this file to run extensions.

The config deliberately sets modern Node/ESM options because Pi and its dependencies publish modern type definitions:

- `target: "ES2022"` avoids false errors from modern `.d.ts` syntax.
- `module` and `moduleResolution: "NodeNext"` match Node ESM and this directory's `"type": "module"` package.
- `skipLibCheck: true` prevents dependency declaration-file noise from drowning out extension diagnostics.
- `types: ["node"]` gives extensions Node globals without pulling in unrelated ambient types.
- `noEmit: true` keeps TypeScript checks from writing generated files into the dotfiles repo.

The adjacent `package.json`, lockfile, `node_modules/`, and `tsconfig.json` are ignored by stow on purpose: they support local editor/type-checking only. Runtime extension imports should still be valid from Pi's actual extension loading environment.
