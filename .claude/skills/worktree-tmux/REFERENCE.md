# `wt` Reference

Full command catalog, metadata schema, and edge cases for the worktree-tmux
skill. `wt` lives at `~/.local/bin/wt` (stowed from `~/dot-files/.local/bin/wt`,
modules in `~/.config/ivu/wt/*.bash`).

## Command catalog

### `wt root [path]`
Print the main repo root, resolving linked worktrees back to their source repo.
Use this to normalize a path inside a worktree to the main repo root before
calling `wt worktrees add --repo`.

### `wt repos`
Cached repo discovery under `~/dev` (configurable via `--dev-dir`).
- `list [--dev-dir DIR] [--format plain|fzf|json]` — print cached repos. `fzf` includes pin markers.
- `refresh [--dev-dir DIR]` — rescan and update the cache.
- `pin list` — pinned repo paths in picker order.
- `pin toggle <repo>` — pin/unpin a repo path relative to the dev dir.

### `wt branches [--fetch]`
List local + remote branches, deduplicated and picker-friendly. `--fetch`
prints current branches immediately, then appends newly fetched ones.

### `wt worktrees`
- `list [--repo PATH] [--merged] [--format plain|fzf|json]`
  - `json`: `[{worktree_dir, branch, merged, worktree_path}]`
  - `fzf`: merged worktrees get a `✓ ` prefix marker.
  - `--merged` filters to merged branches only.
- `add <branch|pr-url> [--session NAME] [--base REF] [--fetch] [--repo PATH] [--format text|json]`
  - Creates/sets up a worktree using `.ivu.yml` (`copy_paths`, `symlinks`).
  - Branch slashes → dashes in the worktree dir name (`feat/auth` → `feat-auth`).
  - `--base REF`: create from an explicit base (local ref, `origin/<branch>`, or a remote branch name that gets fetched). Defaults to `origin/<base_branch>` for new branches.
  - `--session NAME`: pass-through tmux session-name override (validated: no whitespace, no `:`). Does not affect git setup.
  - `--fetch`: refresh remote refs first. Existing local branches already fast-forward to origin by default; `--fetch` only matters for branches with no cached remote-tracking ref.
  - PR URL (`https://github.com/owner/repo/pull/123`): resolved to head branch via `gh`. Cross-repo PRs add a `pr-<owner>` remote and fetch the head ref.
  - `--format json`: emit full metadata (see schema below). `--format text` (default): print the worktree path only.
- `rm <worktree-dir-or-path> [--repo PATH]` — remove a worktree and prune stale git metadata. Accepts a dir name (resolved under the worktree root), or an absolute/`~`-prefixed path.

### `wt config`
- `init [--repo PATH]` — create `.ivu.yml` from `~/.config/ivu/template.yml` if missing.
- `get <key> [--repo PATH]` — read a key under `worktree.*` from repo config.

## `wt worktrees add --format json` metadata schema

```json
{
  "repo_root": "/abs/path/to/main/repo",
  "repo_safe_name": "myrepo",
  "branch": "feat/auth",
  "base_branch": "main",
  "worktree_dir": "feat-auth",
  "worktree_path": "/abs/path/to/worktrees/myrepo/feat-auth",
  "worktree_root": "~/.worktrees",
  "startup_cmd": "",
  "suppress_tmux_startup_hook": true,
  "session_name": "",
  "created": true,
  "config_created": false,
  "copied": 0,
  "linked": 2,
  "base_source": "origin/develop",
  "base_ref": "origin/develop"
}
```

| Field | Meaning |
| --- | --- |
| `repo_root` | Main repo root (source of the worktree). |
| `repo_safe_name` | Repo basename sanitized for session names (`.`/`:` → `-`). |
| `worktree_dir` | Worktree directory name (branch slashes → dashes). |
| `worktree_path` | Absolute path to the worktree. Use as tmux session cwd. |
| `worktree_root` | Raw `dir` config value (the configured worktree container). |
| `session_name` | Explicit tmux session name if `--session` was passed, else `""`. |
| `startup_cmd` | Command to run in the first pane (from `.ivu.yml`). |
| `suppress_tmux_startup_hook` | If true, skip the default git session layout (nvim + lazygit + shell). |
| `created` | Whether the worktree dir was newly created this run. |
| `config_created` | Whether `.ivu.yml` was auto-created from the template this run. |
| `copied` / `linked` | Counts of `copy_paths` / `symlinks` applied. |
| `base_source` / `base_ref` | Present only when `--base` was used. |

### Session name derivation
- If `session_name` is non-empty, use it verbatim.
- Otherwise: `<repo_safe_name>/wt/<worktree_dir>`.

## `.ivu.yml` reference

Per-repo config at the repo root (`.ivu.yml` or `.ivu.yaml`). Template:
`~/.config/ivu/template.yml`. Read via `yq` under the `worktree.*` key.

```yaml
worktree:
  dir: ~/.worktrees        # relative → anchored to repo root; ~ or / → shared root nested under repo name
  base_branch:            # auto-detected from origin/HEAD when empty (main/master/develop)
  copy_paths:             # files copied (independent per worktree)
    # - .env
  symlinks:               # files/dirs symlinked (stay in sync with main repo)
    - .claude/settings.local.json
    - .pi/settings.json
  startup_cmd: ""         # run in the first tmux pane via send-keys
  suppress_tmux_startup_hook: true   # true → skip default nvim+lazygit+shell layout
```

`dir` resolution:
- Relative (`dir: .worktrees`) → `<repo_root>/<dir>/<worktree_dir>`.
- `~/`-prefixed (`dir: ~/.worktrees`) → `~/.worktrees/<repo_safe_name>/<worktree_dir>`.
- Absolute (`dir: /srv/wt`) → `/srv/wt/<repo_safe_name>/<worktree_dir>`.

Shared roots nest under `repo_safe_name` so multiple repos sharing one root
don't collide. Relative roots also add the worktree container to
`.git/info/exclude` so it stays out of `git status`.

## Edge cases

- **Branch already checked out elsewhere**: `wt` reuses the existing checkout instead of erroring, and skips file setup for it. `created` will be `false`.
- **Stale worktree record**: if a worktree dir is gone (e.g. removed via LazyGit), `wt` prunes it before creating.
- **Stale tmux session with missing cwd**: when reusing a session whose pane cwd no longer exists, replace the session (rename to `<session>-stale-$$`, create fresh, kill stale) so tools like lazygit don't panic on git refresh.
- **Forked PR**: `wt` adds a `pr-<fork_owner>` remote and fetches the head ref, then creates a local tracking branch so the standard local strategy applies.
- **`tmux send-keys` target**: target a **pane id**, not a bare session name, when the session name contains slashes — tmux treats an exact slash-containing session target ambiguously. Capture the pane id from `tmux new-session -d -P -F '#{pane_id}'`.
- **Interactive human path**: `prefix + w` opens the `tmux_worktree` floating popup (`~/.config/tmux/bin/worktree/tmux_worktree`), which dispatches to `tmux_worktree_add` / `tmux_worktree_rm`. Those scripts own the spinner, stale-session replacement, and `switch-client`. Prefer them only when you want the full interactive lifecycle; for agent/headless use, drive `wt` + `tmux new-session -d` directly.

## Dependency requirements

`wt` shells out to: `git`, `yq` (config parsing), `python3` (JSON emit/parse),
`gh` (PR URL resolution), `fzf` (interactive pickers). Ensure these are on
`PATH` (or `~/.local/bin/wt` falls back to `wt` from `PATH`).
