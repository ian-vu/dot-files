# Agent Instructions - meeting-sync

Self-contained tool that syncs Notion AI Meeting Notes into the `heidi` Obsidian
vault, one-way (Notion → Obsidian). Zero runtime dependencies; Node 22+ native
`fetch`.

Read `PLAN.md` first - it is the source of truth for design, decisions, the
Notion API contract, the file format, and the phased rollout.

## Layout

- `bin/meeting-sync` - entrypoint. `--probe` mode (Phase 1) prints API results.
- `src/config.mjs` - loads `config.json`, expands `~`, decrypts the token.
- `src/notion.mjs` - Notion API client (`queryMeetingNotes`, block children).
- `config.json` - checked in, no secrets. Vault path, folder, toggles, `op://` ref.
- `.cache/notion-token.txt` - gitignored temp cache of the token fetched from
  1Password (for background/fallback runs). Refresh with `just tools meeting-sync refresh-token`.
- `deploy/launchagents/` - launchd plist, stowed to `~/Library/LaunchAgents/`
  via `--target` (see `.justfile` `install`).
- `raycast/` - Raycast on-demand script; add this dir in Raycast settings.

## Conventions

- The whole `tools/` tree is stow-ignored at the repo root (`^/tools`). Nothing
  here is symlinked into `$HOME` by `stow --no-folding .`. The launchd plist is
  the only exception and is placed by the `install` recipe, not the root run.
- Run recipes as `just tools meeting-sync <recipe>`.
- Secrets live in 1Password and are fetched at runtime via the `op` CLI
  (`op read "<op:// reference>"`). A gitignored local cache (`.cache/`) is the
  only on-disk copy, used by background/fallback runs. No age, no committed secrets.
- The meeting-notes API is beta and version-pinned via `config.notionVersion`
  (`Notion-Version` header). Bump there, not in code.

## Status

Phase 1 (probe) is scaffolded. Phases 2–4 (block→markdown, marker-based upsert,
launchd/Raycast automation, polish) are described in `PLAN.md` and not yet built.
