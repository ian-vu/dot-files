# Worktree Scripts

Git worktree + tmux session manager. Bound to `prefix + w`.

## Architecture

`tmux_worktree` is the entry point and orchestrator. It opens a tmux popup and runs a mode-switching loop inside it. Each mode launches a separate fzf instance with `--expect` keys for transitions. When the user makes a selection, it dispatches to the appropriate action script.

```
tmux_worktree (popup + picker loop)
  ├── mode: repo     → tmux_worktree_pick_repo
  ├── mode: branch   → fzf (type/select branch) → exec tmux_worktree_add
  └── mode: worktree → fzf (select worktrees)    → tmux_worktree_rm
```

## Scripts

| Script | Responsibility |
|---|---|
| `tmux_worktree` | Entry point. Opens popup, runs picker loop. Owns all fzf UI and mode transitions. Dispatches to add/rm. |
| `tmux_worktree_add` | Pure creation. Takes `<repo_root> <branch>`, creates worktree, sets up files, creates tmux session, switches to it. No fzf. |
| `tmux_worktree_rm` | Pure removal. Takes `<repo_root> <worktree_dir>`, kills session, removes worktree directory. No fzf. |
| `tmux_worktree_pick_repo` | Standalone repo picker. Lists git repos under `~/dev` with fzf. Returns absolute path on stdout. Has its own pinning system and cache. |
| `tmux_worktree_list_branches` | Data source. Lists deduplicated local+remote branches. Supports `--fetch` for streaming background fetch. |
| `tmux_worktree_list_worktrees` | Data source. Lists worktree directories with merge status prefix (`⎇ ` merged, `  ` not merged). |

## Mode transitions

- **ctrl-p**: switch to repo picker (from any mode)
- **ctrl-w**: switch from branch → worktree mode
- **ctrl-b**: switch from worktree → branch mode (also reloads existing branches within branch mode)
- **Enter in branch mode**: creates/switches to worktree via `tmux_worktree_add`
- **Enter in worktree mode**: removes selected worktrees via `tmux_worktree_rm`
- **ctrl-x in worktree mode**: removes selected worktrees without closing fzf

## Key conventions

- Per-repo config lives in `.ivu.yml` (see `~/.config/ivu/template.yml`).
- Session names follow `<repo>/wt/<worktree_dir>` convention, parsed by `format-session.sh` for the status bar.
- `tmux_worktree` uses `exec` when handing off to `tmux_worktree_add` so the popup lifecycle (spinners, session switch) stays in one process.
