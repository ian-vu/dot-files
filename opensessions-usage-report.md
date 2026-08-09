# opensessions usage in this dotfiles repo

A report of every place this repository integrates with [opensessions](https://github.com/Ataraxy-Labs/opensessions) — a tmux-native sidebar for session and agent status.

opensessions is consumed three ways here:

1. **As a tmux plugin** installed via `set -g @plugin` (the bulk of the integration).
2. **As a long-running HTTP server** the tmux plugin starts lazily, which this repo's hooks and Pi extension talk to.
3. **As a set of binaries** (`opensessions-server`, etc.) that the `kill-servers` just recipe deliberately spares.

The sidebar pane is identified throughout by `pane_title == "opensessions-sidebar"`. That title is the single contract every sidebar-aware script and keybinding keys off.

---

## 1. tmux plugin registration & environment — `.config/tmux/tmux.conf`

```conf
set -g @plugin 'https://github.com/Ataraxy-Labs/opensessions'
```

Three environment variables are configured around the plugin:

| Variable | Purpose | Set in |
|---|---|---|
| `OPENSESSIONS_LAZYDIFF` | Routes diff actions through the Diffview wrapper instead of opensessions' built-in LazyDiff. | `tmux.conf` (`set-environment -gF … "#{HOME}/.local/bin/opensessions-diffview"`) |
| `OPENSESSIONS_PORT` | Concrete port for the lazy server, resolved from the socket-derived port before `hooks.conf` is parsed. | `tmux.conf` via `server-common.sh`; unset first with `-gu` so a stale value never persists. |
| `OPENSESSIONS_SERVER_KEY` | Cleared (`-gu`) so the plugin re-derives it from the tmux socket. | `tmux.conf` |

The port resolution runs `run-shell` sourcing `plugins/opensessions/.../server-common.sh`, then publishes `PORT` back into the tmux global environment so later hooks can embed a concrete `http://127.0.0.1:$PORT/...` URL even though the server itself starts lazily.

A footer comment in `tmux.conf` notes a startup ordering hazard: the plugin installs its own hooks with `set-hook -g` (replace-whole-array) after its server starts, which wipes user hooks sourced earlier. A backgrounded helper (`tmux-apply-hooks-after-plugin.sh`) waits for the plugin to finish, then re-sources `hooks.conf` so user hooks land after the plugin's and coexist.

---

## 2. tmux hooks — `.config/tmux/hooks.conf`

### Coexistence strategy

opensessions registers several of the same hooks this repo uses (`session-created`, `client-session-changed`, `after-new-window`, …) with plain `set-hook -g name cmd`, which **replaces the whole hook array**. To coexist, every user hook in `hooks.conf` is preceded by:

```
~/.config/tmux/bin/tmux-dedup-hook <hook> <marker>
```

which removes prior entries matching a marker (highest index first), then re-appends with `set-hook -ag`. Result: exactly one user entry per event, reload-safe, order-independent vs the plugin.

### Lazy autostart — `after-new-window`

On the first new window, a hook sources `server-common.sh`, calls `ensure_server`, then:

- If `@opensessions-autostarted == 1`: `POST /ensure-sidebar` with `client_tty|session_name|window_id|pane_id|pane_active`.
- Else: set `@opensessions-autostarted 1` and `POST /toggle` to reveal the sidebar once.

The `curl` calls are best-effort (`-m 0.2 --connect-timeout 0.1 … || true`) so a transient timeout while the server is starting never surfaces as a tmux run-shell error. The dedup markers are `@opensessions-autostarted` and `'ensure_server && curl'`.

### Sidebar keepalive — `client-session-changed`

```
set-hook -ag client-session-changed 'run-shell -b "sleep 0.2; … ensure-sidebar.sh …"'
```

Keeps the sidebar available across client session changes. Once the plugin server is running its own equivalent hook makes this a redundant, idempotent backup.

### Sidebar reaping — `client-session-changed`

Backgrounded with a delay so the plugin's own session-change handling settles first, then runs `reap-detached-sidebars.sh` (see §4). This is the cleanup half of the sidebar lifecycle: ensure on attach, reap on detach.

---

## 3. sidebar-aware keybindings — `.config/tmux/key_bindings.conf`

All sidebar bindings gate on `#{==:#{pane_title},opensessions-sidebar}` so they only redirect keys when the sidebar pane is focused, and pass the original key through everywhere else (normal typing unaffected).

### Pane navigation (Colemak: h/n/e/i)

- `M-h` / `M-i`: when sidebar is focused, `select-pane -L` / `-R` (leave the sidebar for the adjacent tmux pane). Otherwise the normal vim-tmux-navigator path through `tmux_navigate_unzoom`.
- `M-n` / `M-e`: when sidebar is focused, `send-keys Right` / `Left` (move between the session list and agent list **inside** the sidebar). Otherwise normal navigation.

This split exists because opensessions has two internal columns (sessions, agents) that `M-n`/`M-e` traverse, while `M-h`/`M-i` still leave the sidebar entirely.

### Sidebar-aware zoom — `prefix+z`

Keeps the sidebar visible while zooming the main pane, capping it at `@zoom_max_width_percent` (75% default) so text isn't stretched across a large monitor. Falls back to native zoom in windows without a sidebar. `prefix+Z` keeps tmux's default full-window zoom. Pane navigation exits this zoom via `tmux_navigate_unzoom` (see §4).

### List navigation shims — bare `n` / `e`

opensessions hardcodes Vim-style list navigation (`j`/`k`) inside the sidebar. These shims translate bare Colemak `n`→`Down` and `e`→`Up` only when the sidebar is focused:

```
bind-key -n n if-shell -F '#{==:#{pane_title},opensessions-sidebar}' 'send-keys Down' 'send-keys n'
bind-key -n e if-shell -F '#{==:#{pane_title},opensessions-sidebar}' 'send-keys Up'   'send-keys e'
```

### Diff launch remap — `g` / `G` (was `l` / `L`)

The opensessions diff action is moved to the git-mnemonic `g`/`G`:

| Key | Sidebar focused | Elsewhere |
|---|---|---|
| `g` | `send-keys l` (opensessions popup) | normal `g` |
| `G` | `new-window … opensessions-diffview` (full review window) | normal `G` |
| `l` | `display-message "opensessions diff moved to g/G"` | normal `l` |
| `L` | same display-message | normal `L` |

The `l`/`L` guards display a hint so muscle memory gets a pointer instead of silently doing nothing.

---

## 4. sidebar-aware tmux scripts — `.config/tmux/`

### `.config/tmux/bin/tmux-dedup-hook`

General-purpose helper, not opensessions-specific, but built for coexistence with opensessions. Removes every global hook entry for `<hook>` whose command contains `<marker>`, highest index first, so earlier removals don't shift remaining indices. Pair with `set-hook -ag` for reload-safe, self-cleaning hooks that survive the plugin's `set-hook -g` replace-whole-array behavior.

### `.config/tmux/bin/tmux_navigate_unzoom`

Directional pane navigation that first exits the sidebar-aware zoom (`tmux_zoom_sidebar`, bound to `prefix+z`). Mirrors native tmux zoom's exit-on-navigate so you never land on a shrunken "padding" pane while zoomed. Used by the `M-h`/`M-n`/`M-e`/`M-i` bindings above.

### `.config/tmux/scripts/apply-theme.sh`

Offsets the window list past the sidebar so it lines up with the main pane instead of being covered. Reads `sidebarWidth` and `sidebarPosition` from `~/.config/opensessions/config.json`:

```sh
OS_CONFIG="$HOME/.config/opensessions/config.json"
SIDEBAR_POS=$(jq -r '.sidebarPosition // "left"' "$OS_CONFIG" …)
if [ "$SIDEBAR_POS" = "left" ]; then
  SIDEBAR_WIDTH=$(jq -r '.sidebarWidth // 45' "$OS_CONFIG" …)
  SIDEBAR_PAD="$(printf '%*s' "$SIDEBAR_WIDTH" '')#[fg=${THEME_BORDER}]┃…"
fi
tmux set -g status-left "…#{?#{m:*opensessions-sidebar*,#{P:#{pane_title}\|}},${SIDEBAR_PAD},}"
```

The padding is conditional at render time: it only shows when the current window contains a pane titled `opensessions-sidebar`, so windows without the sidebar keep the window list flush left. A thin `┃` in the pane-border color visually continues the sidebar/main split into the status line. Window 1's pill drops its leading arrow because it sits flush against the sidebar's `┃`.

### `.config/tmux/scripts/reap-detached-sidebars.sh`

Kills `opensessions-sidebar` panes in detached sessions idle longer than a grace period (default 30 min; override with `$1` in seconds). Rationale: the plugin keeps one sidebar pane per window alive even after detach, so background sessions accumulate dozens of idle sidebar TUI processes (~0.8% CPU each; 24 observed after 12h with 13 sessions), which also inflates the system process table.

Guards:
- only panes titled `opensessions-sidebar`
- only `session_attached == 0`
- only sessions idle past the grace period (keyed off `#{session_activity}`)
- never the last pane of a single-window session (would kill the session)
- the plugin's `_os_stash` session (hidden-sidebar storage) is left alone

Safe because the plugin's `ensure-sidebar` hooks respawn a sidebar on demand when a client reattaches. Invoked from `hooks.conf` on `client-session-changed`.

### `.config/tmux/bin/tmux_resize_balance`

Resize-toward-half without `select-layout` (which reflows mixed/nested layouts). Sidebar-aware: the opensessions sidebar is a full-height pane joined to the window edge at a fixed width, and `#{window_width}` includes it, so `window_width/2` overshoots and steals columns from the pane's horizontal sibling. The script subtracts the sidebar width when one is present:

```sh
sidebar_width() {
  tmux list-panes -F '#{pane_title} #{pane_width}' 2>/dev/null |
    awk '$1 == "opensessions-sidebar" { print $2; exit }'
}
…
target=$(((window_size - sidebar) / 2))
```

Vertical balance is unaffected because the sidebar is full-height.

---

## 5. Diffview wrapper — `.local/bin/opensessions-diffview`

Shell script that opens local Git changes in Neovim Diffview for tmux and opensessions diff actions. Registered as `OPENSESSIONS_LAZYDIFF` in `tmux.conf`. opensessions may append LazyDiff-only flags like `--branch`; `DiffviewOpen` with no range shows current working-tree/index changes, so arguments are ignored. This makes the sidebar's diff action always open current local changes in nvim rather than opensessions' built-in LazyDiff.

Bound directly to `G` (uppercase) in sidebar focus, which opens it in a full tmux window for review (see §3).

---

## 6. `kill-servers` just recipe — `.justfile`

```just
[group('dev')]
kill-servers:
    #!/usr/bin/env bash
    set -u
    ports=({3000..3010} {8000..8100})
    …
        case "$comm" in
            opensessions-*) echo "skipping opensessions pid $pid on port $port ($comm)" ;;
            *) safe_pids+=("$pid") ;;
        esac
```

Kills processes listening on common dev server ports (3000–3010, 8000–8100) but **never kills opensessions**. `opensessions-server` binds to port 7391 by default or `22000 + hash-of-tmux-socket` (range 22000–41999), neither of which overlaps the dev ranges. The guard is defensive: if someone ever sets `OPENSESSIONS_PORT` to a dev port, any process whose basename matches `opensessions-*` is still spared so the tmux plugin stays alive.

---

## 7. Pi extension — `.pi/agent/extensions/opensessions-runtime.ts`

A local copy of the official opensessions Pi extension (`integrations/pi-extension/opensessions-runtime.ts`) with compatibility patches:

- imports types from `@earendil-works/pi-coding-agent`
- uses `ctx.cwd` for the current directory
- preserves session id/name fallbacks
- leaves the heartbeat `unref()` call
- captures session data as plain data at `session_start` so the heartbeat timer never touches session-bound `pi`/`ctx` objects, which go stale (and throw) after a session replacement (`newSession`/`fork`/`switchSession`/`reload`)

Registers this Pi process with the opensessions server so the sidebar can map live Pi sessions to exact tmux panes. Network failures are ignored because the server starts lazily.

### Server URL resolution — mirrors the Rust runtime

| Source | Value |
|---|---|
| `OPENSESSIONS_URL` | explicit URL (trailing slashes stripped) |
| `OPENSESSIONS_PORT` | explicit port |
| `OPENSESSIONS_SERVER_KEY` | explicit key |
| fallback | `DEFAULT_SERVER_PORT = 7391`, plus `RUST_SERVER_PORT_BASE = 22000` + hash-of-tmux-socket (range 22000–41999) |

### Events posted

- **Runtime registration** (`PiRuntimePayload`): `pid`, `ppid`, `sessionId`, `sessionFile`, `cwd`, `sessionName`, `ts` — posted at session start and every `HEARTBEAT_MS = 5_000` (timer `unref`'d so it never keeps the process alive).
- **Agent events** (`AgentEventPayload`): `agent: "pi"`, `status: running|done|error|interrupted`, `threadId`, `threadName`, `lastUserPrompt`, `projectDir`, `paneId`, `ts` — posted on agent status transitions. `paneId` is what opensessions uses to route agent-row clicks to the right tmux pane.

`post()` iterates all resolved server URLs and returns on the first 2xx; failures are swallowed and retried on the next event/heartbeat.

### Update procedure (from the file header)

Fetch the upstream file, diff against this copy, port relevant changes, keep the local compatibility patches, and verify with:

```
(cd .pi/agent/extensions && npx tsc --project tsconfig.json)
```

---

## 8. stow ignore — `.stow-local-ignore`

The Pi extension source is repo-local-only (not symlinked into `$HOME`). `.stow-local-ignore` excludes the extension's package files and `node_modules`:

```
^/\.pi/agent/extensions/package\.json
^/\.pi/agent/extensions/package-lock\.json
^/\.pi/agent/extensions/tsconfig\.json
^/\.pi/agent/extensions/node_modules
```

The extension source itself (`opensessions-runtime.ts`) **is** stowed (no ignore entry), so it is symlinked into `~/.pi/agent/extensions/`.

---

## Summary table

| File | Role |
|---|---|
| `.config/tmux/tmux.conf` | Plugin install; `OPENSESSIONS_LAZYDIFF`/`PORT`/`SERVER_KEY` env; port pre-resolution; plugin-hook-rewrite mitigation |
| `.config/tmux/hooks.conf` | Lazy autostart (`after-new-window`), sidebar keepalive + reap (`client-session-changed`), dedup-coexistence strategy |
| `.config/tmux/key_bindings.conf` | Sidebar-aware navigation (`M-h/n/e/i`), zoom (`prefix+z`), list shims (`n`/`e`), diff remap (`g`/`G`) |
| `.config/tmux/bin/tmux-dedup-hook` | Reload-safe hook coexistence with the plugin's `set-hook -g` replaces |
| `.config/tmux/bin/tmux_navigate_unzoom` | Exits sidebar-aware zoom on pane navigation |
| `.config/tmux/scripts/apply-theme.sh` | Status-left padding offset from `opensessions/config.json` `sidebarWidth`/`sidebarPosition` |
| `.config/tmux/scripts/reap-detached-sidebars.sh` | Kills idle sidebar panes in detached sessions |
| `.config/tmux/bin/tmux_resize_balance` | Sidebar-width-aware horizontal resize |
| `.local/bin/opensessions-diffview` | Diffview wrapper for `OPENSESSIONS_LAZYDIFF` |
| `.justfile` (`kill-servers`) | Spares `opensessions-*` binaries when killing dev-port processes |
| `.pi/agent/extensions/opensessions-runtime.ts` | Registers Pi processes with the opensessions server; agent-status events |
| `.stow-local-ignore` | Keeps extension package files / `node_modules` repo-local |
