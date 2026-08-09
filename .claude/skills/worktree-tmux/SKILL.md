---
name: worktree-tmux
description: Create and manage git worktrees plus their tmux sessions using the `wt` CLI. Use when the user asks to create/switch/remove a worktree, open a branch or PR in a worktree, start a tmux session for a branch, list worktrees, or configure per-repo worktree settings (.ivu.yml).
---

# Worktree + Tmux (via `wt`)

Manage git worktrees and their tmux sessions through the reusable `wt` CLI at
`~/.local/bin/wt`. `wt` owns git/worktree behavior, `.ivu.yml` config, and file
setup; tmux owns only session lifecycle. Prefer `wt` over raw `git worktree`.

## Operating rules

- Always go through `wt` for worktree create/list/remove and branch/repo discovery. It handles `.ivu.yml`, copy/symlink setup, PR-URL → branch resolution (incl. forks), stale-worktree pruning, and machine-readable metadata.
- Derive session names and paths from `wt worktrees add --format json` metadata — never guess.
- Default session name: `<repo_safe_name>/wt/<worktree_dir>` (slashes in the branch become dashes in the dir). Honor an explicit `session_name` from metadata when present.
- Create tmux sessions **detached** (`tmux new-session -d`) so you don't yank the user's client. Only switch the client if the user explicitly asks to jump to the session.
- Respect `.ivu.yml`: run `startup_cmd` in the first pane, and honor `suppress_tmux_startup_hook`.
- Removing a worktree must also kill any tmux session rooted at that worktree path.

## Quick start: create worktree + session

```bash
# 1. Create the worktree and get metadata (run from inside the repo, or pass --repo)
wt worktrees add feat/auth --format json
# → {"worktree_path":"...","worktree_dir":"feat-auth","repo_safe_name":"...",
#    "session_name":"","startup_cmd":"","suppress_tmux_startup_hook":true,
#    "created":true,"config_created":false,"copied":0,"linked":2,...}

# 2. Start a detached tmux session from the metadata
SESSION="myrepo/wt/feat-auth"   # = repo_safe_name/wt/<worktree_dir> unless session_name set
tmux new-session -d -s "$SESSION" -c "$WORKTREE_PATH"
# 3. Run startup_cmd in the first pane if non-empty
tmux send-keys -t "$SESSION" "$STARTUP_CMD" Enter
```

For a PR: `wt worktrees add https://github.com/owner/repo/pull/123 --format json`
(resolves head branch via `gh`; forks get a `pr-<owner>` remote + fetch).

## Workflows

### Create / switch to a worktree
1. `wt worktrees add <branch|pr-url> [--base REF] [--fetch] [--repo PATH] --format json`
2. Read `worktree_path`, `session_name` (else build `<repo_safe_name>/wt/<worktree_dir>`), `startup_cmd`, `suppress_tmux_startup_hook`.
3. If a session with that name exists and `created` is false, just switch to it. If `created` is true, replace the stale session (the worktree was recreated).
4. `tmux new-session -d -s "$SESSION" -c "$WORKTREE_PATH"`; send `startup_cmd` if set.

### List worktrees
`wt worktrees list --format json` → `[{worktree_dir, branch, merged, worktree_path}]`.
Add `--merged` to filter to merged branches only.

### Remove a worktree
1. Find the worktree path: `wt worktrees list --format json` (match `worktree_dir`).
2. Kill tmux sessions whose `#{session_path}` equals that path:
   `tmux list-sessions -F '#{session_name}\t#{session_path}'`, kill matches.
3. Also kill the default-named session `<repo_safe_name>/wt/<worktree_dir>`.
4. `wt worktrees rm <worktree-dir> --repo <repo>`.

### Configure a repo
`wt config init` creates `.ivu.yml` from `~/.config/ivu/template.yml`. Edit
`worktree.dir`, `base_branch`, `copy_paths`, `symlinks`, `startup_cmd`,
`suppress_tmux_startup_hook`. Read a key with `wt config get <key>`.

### Discover repos / branches
- `wt repos list [--format fzf|json]` — cached repos under `~/dev` (refresh with `wt repos refresh`; pin with `wt repos pin toggle <repo>`).
- `wt branches [--fetch]` — local + remote branches, deduplicated.

## Key conventions

- `.ivu.yml` / `.ivu.yaml` at the repo root is the source of truth. Missing config is auto-created from the template on first `wt worktrees add`.
- `dir` may be relative (anchored to repo root) or `~`/absolute (shared root, nested under repo name to avoid collisions).
- `--fetch` refreshes remote refs before resolving; existing local branches already fast-forward to origin by default, so `--fetch` only matters for branches with no cached remote-tracking ref.
- The interactive human path is `prefix + w` in tmux (`tmux_worktree` popup). For agent-driven, non-interactive use, call `wt` + `tmux new-session -d` instead of the popup scripts.

See [REFERENCE.md](REFERENCE.md) for the full `wt` command catalog, the complete
JSON metadata schema, `.ivu.yml` reference, and edge cases.
