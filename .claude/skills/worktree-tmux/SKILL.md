---
name: worktree-tmux
description: Create and manage git worktrees and their tmux sessions through the `wt` CLI. Use when the user asks to create, open, switch, list, or remove a worktree; open a branch or GitHub PR in a worktree; manage its tmux session; or edit per-repo `.ivu.yml` worktree settings.
---

# Worktree + Tmux

Use `~/.local/bin/wt` for git/worktree operations. It owns repo and branch
discovery, `.ivu.yml` setup, PR resolution, and worktree metadata. Tmux owns
session creation, switching, and removal. Do not use raw `git worktree` commands.

## Operating rules

- Run `wt` inside the repository or pass `--repo PATH`.
- Use `wt worktrees add --format json`; derive paths and session names from its metadata.
- Use `session_name` when present. Otherwise use `<repo_safe_name>/wt/<worktree_dir>`.
- Create agent-driven tmux sessions detached. Switch the client only when the user asks.
- Capture the pane ID from `tmux new-session -d -P -F '#{pane_id}'`; target that ID for `startup_cmd`.
- When `suppress_tmux_startup_hook` is true, create the session with `TMUX_NO_STARTUP_HOOK=1`.
- Remove tmux sessions rooted at the worktree before removing the worktree.
- Use the interactive popup only when requested; `tmux_worktree_add` switches the active client.

## Create or open a worktree

```bash
wt worktrees add <branch|pr-url> [--session NAME] [--base REF] \
  [--fetch] [--repo PATH] --format json
```

Read these fields from the JSON:

- `worktree_path`: tmux working directory
- `repo_safe_name` and `worktree_dir`: default session name
- `session_name`: optional override
- `startup_cmd` and `suppress_tmux_startup_hook`: session setup
- `created`: whether this invocation created the worktree

Before creating a tmux session:

1. If the exact session exists and `created` is false, leave it running; switch only if requested.
2. If `created` is true, replace an exact-name stale session.
3. Also replace a session if any of its pane working directories no longer exists.
4. Create the replacement detached from `worktree_path`.
5. Send a non-empty `startup_cmd` to the captured pane ID.

For a GitHub PR:

```bash
wt worktrees add https://github.com/owner/repo/pull/123 --format json
```

`wt` resolves the head branch with `gh`; fork PRs get a `pr-<owner>` remote.

## List and remove worktrees

```bash
wt worktrees list [--repo PATH] [--merged] --format json
```

To remove one:

1. Match `worktree_dir` in the JSON list and read `worktree_path`.
2. Kill every tmux session whose `#{session_path}` equals `worktree_path`.
3. Kill the default session `<repo_safe_name>/wt/<worktree_dir>` if it remains.
4. Run `wt worktrees rm <worktree-dir> --repo <repo-root>`.

## Repository configuration

Edit `.ivu.yml` or `.ivu.yaml` at the main repository root. A missing config is
created from `~/.config/ivu/template.yml` on the first `wt worktrees add`.
Relevant keys under `worktree` are `dir`, `base_branch`, `copy_paths`, `symlinks`,
`startup_cmd`, and `suppress_tmux_startup_hook`.

## Discovery

- `wt root [path]`: resolve a linked checkout to its main repository root.
- `wt repos list [--format plain|fzf|json]`: discover repositories under `~/dev`.
- `wt branches [--repo PATH] [--fetch] [--format plain|json]`: list local and remote branches.
- `prefix + w`: open the interactive tmux worktree popup.

See [REFERENCE.md](REFERENCE.md) for metadata, configuration, and edge cases.
