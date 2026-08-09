# Pi Extension Agent Instructions

This directory contains global Pi extensions managed from the dotfiles repo.

## Extension layout

- In `.pi/agent/extensions/*.ts`, keep the `export default` entrypoint near the top before helper implementations so the extension behaviour is easy to read first.

## Runtime vs editor support

- Pi runs `.ts` extensions directly through `jiti`; there is no build step required for runtime.
- `tsconfig.json` exists for Neovim/TypeScript LSP and manual `tsc --project tsconfig.json` checks only.
- Keep `target: "ES2022"`, `module: "NodeNext"`, and `moduleResolution: "NodeNext"` so editor diagnostics match modern Node ESM packages used by Pi.
- Keep `skipLibCheck: true` because Pi's dependency graph includes modern and provider-specific `.d.ts` files that can produce irrelevant diagnostics.
- Keep `noEmit: true` so type checks do not generate JavaScript in the dotfiles repo.

## Dependency policy

`package.json`, `package-lock.json`, and `node_modules/` in this directory are dev-only editor/type-checking support and are intentionally ignored by stow. Do not depend on these files being present in `~/.pi/agent/extensions` at Pi runtime unless they are deliberately made runtime config.

## Stow behavior

Only actual extension files should be symlinked into `~/.pi/agent/extensions`. Repo-only support files such as `tsconfig.json`, local dependencies, and AI context files are ignored by `.stow-local-ignore`; this relies on running `stow --no-folding .` from the repo root.
