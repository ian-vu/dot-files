# Meeting Sync - Plan

One-way sync of Notion AI Meeting Notes into an Obsidian vault, automated on a
schedule and on demand. This document is the source of truth for the design and
build. It captures decisions, architecture, repo layout, file format, and the
phased rollout.

## Goal

Stop hand-creating meeting notes from a template. Let Notion capture and
transcribe meetings (it already integrates with Google Calendar via Notion
Calendar), then pull the AI summary, notes, and transcript into the work
Obsidian vault as durable, searchable, linkable markdown. Personal annotations
stay in an Obsidian-owned section the sync never overwrites.

## Decisions (locked)

| Decision | Choice | Why |
|----------|--------|-----|
| Sync direction | One-way Notion → Obsidian | Notion owns transcription + AI content; Obsidian owns your annotations. Simplest, no write-back conflicts. |
| Automation | Zero-dep Node script + launchd | Node 24 has native `fetch`. Versioned in dotfiles, full control over markdown output. |
| Trigger | Scheduled poll (~20 min) + on-demand | launchd for hands-off; Raycast/CLI to force a sync right after a meeting. |
| Destination | `heidi` vault, dedicated meetings folder | Work meetings stay in the work vault, one file per meeting, dated. |
| Layout | Self-contained `tools/meeting-sync/` | Portable; could later become its own repo. |
| Stow scope | Root stow ignores `tools/`; plist stowed via `--target` | Code stays repo-only; only the launchd plist lands in `~/Library/LaunchAgents/`. |
| just wiring | Nested module `just tools meeting-sync <recipe>` | Mirrors existing `mod brew` / `mod mise` pattern. |
| Secret storage | 1Password item, fetched via `op read`; local `.cache/` temp copy | One root of trust (1Password account); no committed secrets, no age. Cache unblocks background/daemon runs without an `op` session. |

## Architecture

```
Google Calendar ──┐
                  ▼
          Notion Calendar  ──►  Notion AI Meeting Notes
          (auto-attaches         (transcription + AI summary + notes,
           notes to events)       tied to each calendar event)
                                        │
                                        │  Notion API: POST /v1/meeting_notes/query
                                        │  (Notion-Version: 2026-03-11)
                                        ▼
                              bin/meeting-sync  (Node, zero-dep)
                              - query notes where you're an attendee
                              - fetch summary/notes/transcription tab blocks
                              - convert blocks → markdown
                              - marker-based upsert into vault
                                        │
                                        ▼
                    ~/Documents/heidi_obsidian/02_Areas/meetings/YYYY/
                    2025-11-24-eng-standup.md   (one file per meeting)
                          ▲                              ▲
              launchd every ~20 min          Raycast "Sync meetings now"
```

Two capture layers, one knowledge base. Notion is the capture/transcription
engine. Obsidian is the durable knowledge base. The script is a one-way pull.

## Notion API facts (verified)

- `Query meeting notes` endpoint returns meeting-note **block objects**
  (`object: block`, `type: meeting_notes`) where the integration's user is an
  attendee. Naturally scoped to your own meetings.
- Header `Notion-Version: 2026-03-11` (endpoint is beta; pin the version).
- Request body (all optional): `filter` (property filter or `and`/`or`
  combinator on title, attendees, created_time, created_by, last_edited_time,
  last_edited_by), `sort` (array of `{property, direction}`), `limit` (1–50,
  default 50).
- No cursor pagination - refine with `filter`/`sort`/`limit`.
- Each result carries a `meeting_notes` payload with title, status, child-tab
  IDs (summary, notes, transcription), and calendar/recording metadata when
  present.
- To get tab content: `GET /v1/blocks/{tab_id}/children`, then convert blocks to
  markdown.
- Capture path: connect Google Calendar to Notion Calendar; enable AI Meeting
  Notes; create an internal integration and grant it meeting-notes access.

## Repo layout

Everything self-contained under `tools/meeting-sync/`:

```
tools/
├── .justfile                         # namespace: mod meeting-sync 'meeting-sync'
└── meeting-sync/
    ├── PLAN.md                        # this file
    ├── AGENTS.md  CLAUDE.md           # agent context (CLAUDE.md = @AGENTS.md)
    ├── README.md                      # setup + usage
    ├── .justfile                      # probe / run / install / uninstall
    ├── package.json                   # "type": "module", node engine, zero deps
    ├── config.json                    # vault path, folder, poll window, op:// token ref
    ├── bin/
    │   └── meeting-sync               # entrypoint (chmod +x), --probe / --check-token
    ├── src/
    │   ├── config.mjs                 # load config.json + fetch token from 1Password
    │   ├── notion.mjs                 # API client: query notes, fetch tab blocks
    │   ├── blocks-to-md.mjs           # block → markdown converter
    │   └── upsert.mjs                 # marker-based file write, frontmatter, dedupe
    ├── .cache/
    │   └── notion-token.txt           # gitignored temp cache of the 1Password token
    ├── raycast/
    │   └── sync-meetings.sh           # Raycast script (points at bin/meeting-sync)
    └── deploy/
        └── launchagents/
            └── com.ivu.meeting-sync.plist   # → ~/Library/LaunchAgents via --target
```

## Placement mechanisms

Three kinds of files, three ways they reach the OS:

1. **Code / secret / config** - repo-only. Root `stow --no-folding .` ignores
   the folder via `^/tools` in `.stow-local-ignore`. Run by absolute path
   (`~/dot-files/tools/meeting-sync/bin/meeting-sync`).
2. **launchd plist** - stowed to `~/Library/LaunchAgents/` with a dedicated stow
   invocation that overrides the target:
   ```bash
   stow --no-folding --dir tools/meeting-sync/deploy \
       --target "$HOME/Library/LaunchAgents" launchagents
   ```
   `.stow-local-ignore` is read per stow-dir, so this is independent of the root
   run.
3. **Raycast script** - no symlink. Add `~/dot-files/tools/meeting-sync/raycast`
   as a script directory in Raycast settings once.

## just wiring

Root `.justfile` gains one line next to the existing mods:

```make
mod tools 'tools'
```

`tools/.justfile` fans out to each tool:

```make
default:
    @just --list

mod meeting-sync 'meeting-sync'
```

`tools/meeting-sync/.justfile` holds the recipes (cwd-independent via
`source_directory()`, matching `.homebrew/.justfile`):

```make
default:
    @just --list

# Phase 1: probe the Notion API and print what it returns
probe:
    {{ source_directory() }}/bin/meeting-sync --probe

# Run a sync now
run:
    {{ source_directory() }}/bin/meeting-sync

# Deploy the launchd agent (symlinks plist into ~/Library/LaunchAgents)
install:
    cd {{ source_directory() }} && stow --no-folding --dir deploy \
        --target "$HOME/Library/LaunchAgents" launchagents
    launchctl load -w ~/Library/LaunchAgents/com.ivu.meeting-sync.plist

# Remove the launchd agent
uninstall:
    launchctl unload -w ~/Library/LaunchAgents/com.ivu.meeting-sync.plist
    cd {{ source_directory() }} && stow -D --no-folding --dir deploy \
        --target "$HOME/Library/LaunchAgents" launchagents
```

Resulting commands:

| Command | Action |
|---------|--------|
| `just tools meeting-sync probe` | Phase 1 - test the API |
| `just tools meeting-sync run` | Manual sync |
| `just tools meeting-sync install` | Deploy launchd agent |
| `just tools meeting-sync uninstall` | Remove launchd agent |
| `just tools` | List meeting-sync (and future tools) |

## Config

`config.json` (checked in; no secrets):

```json
{
  "vault": "~/Documents/heidi_obsidian",
  "folder": "02_Areas/meetings",
  "yearSubfolders": true,
  "pollWindowMinutes": 1440,
  "syncTranscript": true,
  "filenameFormat": "YYYY-MM-DD-{slug}",
  "notionTokenRef": "op://<vault>/<item>/<field>",
  "tokenCacheFile": ".cache/notion-token.txt"
}
```

- `pollWindowMinutes` - only consider notes with `last_edited_time` within this
  window (keeps each run cheap). Default one day.
- `syncTranscript` - set `false` to store summary + notes only (see data
  governance below).

## File format

One file per meeting, e.g.
`02_Areas/meetings/2025/2025-11-24-eng-standup.md`:

```markdown
---
notion_id: 39eca630-...            # dedupe key
notion_url: https://notion.so/...
date: 2025-11-24
attendees: [you, alice, bob]
status: completed
last_synced: 2025-11-24T15:02:00Z
last_edited_time: 2025-11-24T14:55:00Z   # from Notion, drives re-sync
tags: [meeting/2025/11/24]
---

# Eng Standup

## My Notes           ← YOU own this. Sync never overwrites it.
-

## Action Items       ← YOU own this.
- [ ]

<!-- notion:summary:start -->   ← Notion owns everything between markers
## Summary
...AI summary...
<!-- notion:summary:end -->

<!-- notion:notes:start -->
## Notes
...
<!-- notion:notes:end -->

<!-- notion:transcript:start -->
## Transcript
...
<!-- notion:transcript:end -->
```

### Idempotency and conflict strategy

- Dedupe on `notion_id` in frontmatter (self-healing - no external state file
  needed; the vault is the state).
- Re-sync a file only when Notion's `last_edited_time` is newer than the value
  stored in frontmatter.
- On update, rewrite **only** content between the `<!-- notion:*:start -->` /
  `<!-- notion:*:end -->` markers. Everything outside (My Notes, Action Items,
  your links/backlinks) is preserved verbatim.
- If `syncTranscript` is `false`, the transcript markers are omitted entirely.

## Retiring the old workflow

- `.config/raycast/scripts/create-note-meeting.sh` targets Bear + a manual
  template. Once sync is live, deprecate it - files are created automatically.
- Keep one lightweight Obsidian template for ad-hoc / untranscribed meetings
  (phone calls, hallway chats), with matching `My Notes` / `Action Items`
  headers so manual and synced notes look identical.

## Phased rollout

1. **Phase 1 - capture + probe.** Set up Notion Calendar, AI Meeting Notes, and
   the internal integration. Build `bin/meeting-sync --probe` that calls
   `Query meeting notes` and prints titles/dates/tab IDs. Confirms auth, scope,
   and data shape before building anything else.
2. **Phase 2 - one-shot sync.** Add `notion.mjs` (fetch tab blocks),
   `blocks-to-md.mjs`, and `upsert.mjs`. `just tools meeting-sync run` pulls and
   writes files. Validate markdown quality and marker/upsert logic on real
   meetings.
3. **Phase 3 - automate.** Add the launchd plist + `install`/`uninstall`
   recipes, and the Raycast on-demand script.
4. **Phase 4 - polish.** Auto-extract action items into a dashboard note,
   Neovim keymap to jump to the latest meeting, backlink attendees to people
   notes.

## Secrets

The Notion integration token lives in 1Password. `config.json` holds only an
`op://` reference (`notionTokenRef`); `config.mjs` fetches the value at runtime
with `op read`. No secret is committed, and no age identity is required for this
tool.

On each successful fetch the token is also written to a gitignored local cache
(`.cache/notion-token.txt`, mode 0600) so that background runs (launchd, Phase 3)
and runs without an active `op` session can still authenticate. The cache is a
temp copy, never the source of truth; refresh it with:

```bash
just tools meeting-sync refresh-token
```

One-time setup: create the 1Password item holding the Notion token, copy its
`op://` reference into `config.json`, then run `refresh-token`.

## Caveats and open questions

- **Beta API.** The meeting-notes endpoint is beta and version-pinned
  (`2026-03-11`). Expect occasional schema changes; the marker design isolates
  most churn. `--probe` output is the canary.
- **launchd + symlinked plist.** macOS usually loads a stowed (symlinked) plist
  fine. If it refuses, fall back to a `just` recipe that copies the plist
  instead of symlinking. The daemon reads the local token cache (not `op read`),
  since `op` biometric/session auth isn't available headless; `refresh-token`
  must be run interactively to keep the cache fresh.
- **Block coverage.** `blocks-to-md.mjs` starts with paragraph, headings,
  bulleted/numbered lists, to-do, quote, code, toggle. Unknown block types get a
  visible `<!-- unsupported: {type} -->` marker so gaps are obvious. Consider
  `notion-to-md` only if hand-rolling proves insufficient.
- **Data governance (Heidi is healthcare).** Transcripts of internal meetings
  may reference sensitive material. Confirm whether `~/Documents/heidi_obsidian`
  is cloud-synced and whether storing full transcripts there is acceptable. The
  `syncTranscript: false` toggle stores summary + notes only.
- **Rate limits.** `Query meeting notes` shares Notion's request limits (400/429
  on excess). The `pollWindowMinutes` filter keeps each run to a small result
  set; back off on 429.

## Next step

Scaffold Phase 1: folder skeleton, `AGENTS.md`/`CLAUDE.md`, `package.json`,
`config.json`, the three `.justfile`s, the `^/tools` `.stow-local-ignore` entry,
and `bin/meeting-sync --probe`. Then verify the endpoint returns real data
before building Phases 2–4.
```
