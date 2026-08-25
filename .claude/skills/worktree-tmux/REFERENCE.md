# `wt` Reference

`wt` lives at `~/.local/bin/wt`, stowed from `~/dot-files/.local/bin/wt`. Its
modules live in `~/.config/ivu/wt/*.bash`.

## Commands

### Repository and branch discovery

- `wt root [path]` - resolve a checkout or linked worktree to its main repository root.
- `wt repos list [--dev-dir DIR] [--format plain|fzf|json]` - scan for repositories. `fzf` output includes pin markers.
- `wt repos pin list` - list pinned repository paths.
- `wt repos pin toggle <repo>` - pin or unpin a path relative to the dev directory.
- `wt branches [--repo PATH] [--fetch] [--format plain|json]` - list deduplicated local and remote branches. Plain `--fetch` prints known branches before fetching, then appends newly found branches.

### Worktrees

- `wt worktrees list [--repo PATH] [--merged] [--format plain|fzf|json]`
  - JSON fields: `worktree_dir`, `branch`, `merged`, `worktree_path`.
  - `--merged` returns only worktrees whose branch content is merged into the configured base.
- `wt worktrees add <branch|pr-url> [--session NAME] [--base REF] [--fetch] [--local-base] [--repo PATH] [--format text|json]`
  - Branch slashes become dashes in the worktree directory.
  - `--session NAME` passes a tmux session override through JSON metadata. Names cannot contain whitespace or `:`.
  - New branches fetch the configured base from origin and start from the refreshed `origin/<base_branch>` ref. `--local-base` skips that fetch, starts from the local `<base_branch>`, and marks JSON metadata for a later synchronization.
  - `--base REF` creates a new branch from a local ref, `origin/<branch>`, or a branch fetched from origin.
  - Existing local branches fast-forward to `origin/<branch>` only when the local branch is an ancestor; diverged local commits are preserved.
  - A GitHub PR URL is resolved through `gh`. Fork PRs add a `pr-<owner>` remote and create a local branch from the fetched head.
  - Text output is the worktree path; JSON output contains the full metadata below.
- `wt worktrees rm <worktree-dir-or-path> [--repo PATH]`
  - A name resolves under the configured worktree root.
  - Absolute and `~/`-prefixed paths are accepted.
  - Removal prunes stale git worktree metadata.

## Add metadata

`wt worktrees add <branch> --format json` returns:

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
  "base_sync_pending": false,
  "base_sync_branch": "",
  "created": true,
  "config_created": false,
  "copied": 0,
  "linked": 2,
  "base_source": "origin/develop",
  "base_ref": "origin/develop"
}
```

`base_source` and `base_ref` appear only with `--base`. If `session_name` is
empty, derive it as `<repo_safe_name>/wt/<worktree_dir>`.

## `.ivu.yml`

The config is `.ivu.yml` or `.ivu.yaml` at the main repository root. A missing
config is copied from `~/.config/ivu/template.yml` by the first worktree add.

```yaml
worktree:
  dir: ~/.worktrees
  base_branch:
  copy_paths:
    # - .env
  symlinks:
    - .claude/settings.local.json
    - .pi/settings.json
  startup_cmd: ""
  suppress_tmux_startup_hook: true
```

Path resolution:

- Relative `dir` → `<repo_root>/<dir>/<worktree_dir>`
- `~/`-prefixed `dir` → `<expanded_dir>/<repo_safe_name>/<worktree_dir>`
- Absolute `dir` → `<dir>/<repo_safe_name>/<worktree_dir>`

Relative worktree containers are added to `.git/info/exclude`. `copy_paths` are
independent copies; `symlinks` point back to the main checkout.

## Tmux lifecycle

For headless or agent-driven use:

- Create sessions with `tmux new-session -d`.
- Add `-P -F '#{pane_id}'` and send `startup_cmd` to the returned pane ID.
- Prefix session targets with `=` for exact matching, such as `tmux has-session -t "=$SESSION"`.
- Set `TMUX_NO_STARTUP_HOOK=1` on `tmux new-session` when metadata says `suppress_tmux_startup_hook: true`.
- Do not switch the client unless requested.

The interactive `prefix + w` popup dispatches to `tmux_worktree_add` and
`tmux_worktree_rm`. The add wrapper creates new branches from the local base,
starts the session, fetches and merges `origin/<base_branch>` in its first pane,
then switches the active client.

## Edge cases

- A branch already checked out elsewhere is reused. File setup is skipped and `created` is false.
- A missing checkout recorded by git is pruned before recreation.
- An existing target directory is accepted only when it is a worktree for the same repository and requested branch. Non-worktree directories, other repositories, detached heads, and slash-to-dash branch collisions fail before file setup.
- Existing local branches are never force-updated when they have diverged from origin.
- An existing tmux session is replaced when the worktree was recreated or a pane working directory disappeared.
- Custom session names cannot be derived during removal, so match sessions by `#{session_path}` before also checking the default name.

## Dependencies

The core CLI requires `git` and `python3`. Configured repositories require `yq`.
PR URLs require `gh`. The interactive tmux popup requires `tmux` and `fzf`.
