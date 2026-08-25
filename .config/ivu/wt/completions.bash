# completions.bash: wt helper functions split out for maintainability.
# zsh completion dispatch for `wt __complete zsh ...`, invoked by .oh-my-zsh/custom/completions/_wt.

complete_main_commands() {
  cat <<'EOF'
root:print main repo root
repos:repo discovery/cache/pins
branches:list local and remote branches
worktrees:manage git worktrees
config:read or initialize .ivu config
help:show help
EOF
}

complete_repos_commands() {
  cat <<'EOF'
list:list cached repositories
refresh:refresh repository cache
pin:manage pinned repositories
EOF
}

complete_repos_pin_commands() {
  cat <<'EOF'
list:list pinned repositories
toggle:toggle a repository pin
EOF
}

complete_worktrees_commands() {
  cat <<'EOF'
list:list worktrees
add:create or set up a worktree
rm:remove a worktree
remove:remove a worktree
EOF
}

complete_config_commands() {
  cat <<'EOF'
init:create .ivu.yml from template if needed
get:print a worktree config value
EOF
}

complete_config_keys() {
  cat <<'EOF'
dir:worktree directory root
base_branch:base branch for new worktrees
startup_cmd:command tmux should run in the session
suppress_tmux_startup_hook:whether tmux should skip default startup hook
copy_paths:paths copied into worktrees
symlinks:paths symlinked into worktrees
EOF
}

complete_format_values() {
  case "$1" in
    repos-list) printf '%s\n' 'plain:plain names' 'fzf:fzf display rows' 'json:JSON array' ;;
    branches) printf '%s\n' 'plain:plain names' 'json:JSON array' ;;
    worktrees-list) printf '%s\n' 'plain:plain names' 'fzf:fzf display rows' 'json:JSON array' ;;
    worktrees-add) printf '%s\n' 'text:worktree path only' 'json:JSON metadata' ;;
  esac
}

completion_repo_arg() {
  local -a words=("$@")
  local i
  for ((i = 0; i < ${#words[@]}; i++)); do
    if [ "${words[$i]}" = "--repo" ] && [ $((i + 1)) -lt ${#words[@]} ]; then
      printf '%s\n' "${words[$((i + 1))]}"
      return 0
    fi
  done
}

complete_repos_plain() {
  repos_list --format plain 2>/dev/null | while IFS= read -r repo; do
    printf '%s:repository\n' "$repo"
  done
}

complete_branches_plain() {
  local repo="$1"
  if [ -n "$repo" ]; then
    branches_cmd --repo "$repo" 2>/dev/null
  else
    branches_cmd 2>/dev/null
  fi | while IFS= read -r branch; do
    printf '%s:branch\n' "$branch"
  done
}

complete_worktrees_plain() {
  local repo="$1"
  if [ -n "$repo" ]; then
    worktrees_list_cmd --repo "$repo" 2>/dev/null
  else
    worktrees_list_cmd 2>/dev/null
  fi | while IFS= read -r wt_dir; do
    printf '%s:worktree\n' "$wt_dir"
  done
}

complete_options() {
  case "$1" in
    repos-list) printf '%s\n' '--dev-dir:repository search root' '--format:output format' ;;
    repos-refresh) printf '%s\n' '--dev-dir:repository search root' ;;
    branches) printf '%s\n' '--repo:repository path' '--fetch:fetch before listing' '--format:output format' ;;
    worktrees-list) printf '%s\n' '--repo:repository path' '--merged:only merged worktrees' '--format:output format' ;;
    worktrees-add) printf '%s\n' '--base:base ref for new branch' '--session:tmux session name override' '--session-name:tmux session name override' '--fetch:refresh refs before adding' '--local-base:create from local base and defer sync' '--repo:repository path' '--format:output format' ;;
    worktrees-rm) printf '%s\n' '--repo:repository path' ;;
    config) printf '%s\n' '--repo:repository path' ;;
  esac
}

complete_arg() {
  local current="$1"; shift
  local -a words=("$@")
  local cur="${words[$((current - 1))]:-}"
  local prev="${words[$((current - 2))]:-}"
  local cmd="${words[1]:-}"
  local sub="${words[2]:-}"
  local third="${words[3]:-}"
  local repo
  repo=$(completion_repo_arg "${words[@]}" || true)

  if [ "$current" -le 2 ]; then
    complete_main_commands
    return 0
  fi

  case "$cmd" in
    repos)
      if [ "$current" -le 3 ]; then
        complete_repos_commands
      elif [ "$sub" = "pin" ] && [ "$current" -le 4 ]; then
        complete_repos_pin_commands
      elif [ "$sub" = "pin" ] && [ "$third" = "toggle" ]; then
        complete_repos_plain
      elif [ "$prev" = "--format" ]; then
        complete_format_values repos-list
      elif [[ "$cur" == --* || "$sub" = "list" || "$sub" = "refresh" ]]; then
        complete_options "repos-$sub"
      fi
      ;;
    branches)
      if [ "$prev" = "--format" ]; then
        complete_format_values branches
      elif [[ "$cur" == --* || "$current" -ge 3 ]]; then
        complete_options branches
      fi
      ;;
    worktrees|wt)
      if [ "$current" -le 3 ]; then
        complete_worktrees_commands
      else
        case "$sub" in
          list)
            if [ "$prev" = "--format" ]; then
              complete_format_values worktrees-list
            else
              complete_options worktrees-list
            fi
            ;;
          add)
            if [ "$prev" = "--format" ]; then
              complete_format_values worktrees-add
            elif [ "$prev" = "--base" ]; then
              complete_branches_plain "$repo"
            elif [ "$prev" = "--session" ] || [ "$prev" = "--session-name" ]; then
              :
            elif [[ "$cur" == --* ]]; then
              complete_options worktrees-add
            elif [ "$prev" != "--repo" ]; then
              complete_branches_plain "$repo"
            fi
            ;;
          rm|remove)
            if [[ "$cur" == --* ]]; then
              complete_options worktrees-rm
            elif [ "$prev" != "--repo" ]; then
              complete_worktrees_plain "$repo"
            fi
            ;;
        esac
      fi
      ;;
    config)
      if [ "$current" -le 3 ]; then
        complete_config_commands
      elif [ "$sub" = "get" ] && [ "$current" -le 4 ]; then
        complete_config_keys
      elif [[ "$cur" == --* || "$current" -ge 4 ]]; then
        complete_options config
      fi
      ;;
    help)
      complete_main_commands
      ;;
  esac
}
