# git.bash: wt helper functions split out for maintainability.

repo_root() {
  local path="${1:-.}"
  git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  local git_common_dir
  git_common_dir=$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  printf '%s\n' "${git_common_dir%/.git}"
}

list_branches_raw() {
  {
    git -C "$REPO_ROOT" branch --format='%(refname:short)'
    # Git can render origin/HEAD as just "origin" with this format; hide it
    # because it is symbolic metadata, not a selectable branch.
    git -C "$REPO_ROOT" branch -r --format='%(refname:short)' | sed 's|^origin/||' | grep -Ev '^(HEAD|origin)$' || true
  } | sort -u
}

is_merged() {
  local branch="$1" base_ref branch_sha base_sha
  branch_sha=$(git -C "$REPO_ROOT" rev-parse "$branch" 2>/dev/null) || return 1
  if git -C "$REPO_ROOT" rev-parse "origin/$BASE_BRANCH" >/dev/null 2>&1; then
    base_ref="origin/$BASE_BRANCH"
  else
    base_ref="$BASE_BRANCH"
  fi
  base_sha=$(git -C "$REPO_ROOT" rev-parse "$base_ref" 2>/dev/null) || return 1
  [ "$branch_sha" = "$base_sha" ] && return 1
  git -C "$REPO_ROOT" diff --quiet "$base_ref...$branch" >/dev/null 2>&1
}

