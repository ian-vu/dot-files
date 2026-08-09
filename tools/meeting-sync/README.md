# meeting-sync

One-way sync of Notion AI Meeting Notes into the `heidi` Obsidian vault. Notion
captures and transcribes meetings (via Notion Calendar ← Google Calendar); this
tool pulls the AI summary, notes, and transcript into dated markdown files. Your
own annotations live in an Obsidian-owned section the sync never overwrites.

See [PLAN.md](./PLAN.md) for the full design.

## Setup

1. **Notion side (one-time):** connect Google Calendar to Notion Calendar,
   enable AI Meeting Notes, and create an internal integration with meeting-notes
   access. Copy the integration token.
2. **Create a 1Password item** holding the Notion integration token (any item
   with the token in a field; copy its `op://...` reference from the 1Password app).
3. **Set the reference** in `config.json` (`notionTokenRef`), then cache it locally:
   ```bash
   just tools meeting-sync refresh-token
   ```
4. **Probe the API** to confirm it returns your meetings:
   ```bash
   just tools meeting-sync probe
   just tools meeting-sync probe --raw   # dump full first result
   ```

## Usage

| Command | Action |
|---------|--------|
| `just tools meeting-sync probe` | Print meeting notes the API returns (Phase 1) |
| `just tools meeting-sync run` | Run a sync (Phase 2, in progress) |
| `just tools meeting-sync install` | Deploy the launchd agent |
| `just tools meeting-sync uninstall` | Remove the launchd agent |
| `just tools meeting-sync refresh-token` | Cache the Notion token from 1Password |

## Config

`config.json` (no secrets):

- `vault` - Obsidian vault path (`~` allowed).
- `folder` - subfolder for meeting files.
- `yearSubfolders` - group files by year.
- `pollWindowMinutes` - only sync notes edited within this window.
- `syncTranscript` - set `false` to store summary + notes only.
- `notionTokenRef` - `op://` reference to the Notion token in 1Password.
- `tokenCacheFile` - gitignored local temp cache of the token (for background/fallback).
- `notionVersion` - `Notion-Version` header (endpoint is beta, pinned).

## Status

Phase 1 (probe) works. Sync, converter, and automation are per `PLAN.md`.
