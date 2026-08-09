# config.bash: wt helper functions split out for maintainability.

find_config() {
  local repo="$1"
  if [ -f "$repo/.ivu.yml" ]; then
    printf '%s\n' "$repo/.ivu.yml"
  elif [ -f "$repo/.ivu.yaml" ]; then
    printf '%s\n' "$repo/.ivu.yaml"
  fi
}

ensure_config() {
  local repo="$1"
  CONFIG_CREATED=false
  CONFIG=$(find_config "$repo" || true)
  if [ -z "${CONFIG:-}" ] && [ -f "$TEMPLATE" ]; then
    # New repos get a documented starting config the first time wt manages them.
    CONFIG="$repo/.ivu.yml"
    cp "$TEMPLATE" "$CONFIG"
    CONFIG_CREATED=true
  fi
}

validate_config() {
  local config="$1"
  [ -n "$config" ] && [ -f "$config" ] || return 0
  require_cmd yq
  yq e '.' "$config" >/dev/null 2>&1 || die "invalid wt config YAML: $config"
}

cfg() {
  local key="$1" default="$2"
  if [ -n "${CONFIG:-}" ] && [ -f "$CONFIG" ]; then
    require_cmd yq
    yq -r ".worktree.$key // \"$default\"" "$CONFIG"
  else
    printf '%s\n' "$default"
  fi
}

cfg_array() {
  local key="$1"
  if [ -n "${CONFIG:-}" ] && [ -f "$CONFIG" ]; then
    require_cmd yq
    yq -r ".worktree.${key}[]?" "$CONFIG" 2>/dev/null
  fi
}

load_context() {
  REPO_ROOT="${1:-}"
  if [ -z "$REPO_ROOT" ]; then
    REPO_ROOT=$(repo_root .) || die "not inside a git worktree; pass --repo"
  fi
  # Accept any path inside a checkout or linked worktree, then normalize to the
  # main repository root so nested worktrees are not created accidentally.
  REPO_ROOT=$(repo_root "$REPO_ROOT") || die "not a git repository: $REPO_ROOT"
  REPO_ROOT=$(cd "$REPO_ROOT" && pwd)

  CONFIG=$(find_config "$REPO_ROOT" || true)
  validate_config "$CONFIG"
  REPO_BASENAME=$(basename "$REPO_ROOT")
  REPO_SAFE_NAME=$(safe_name "$REPO_BASENAME")

  RAW_WT_DIR=$(cfg dir .worktrees)
  STARTUP_CMD=$(cfg startup_cmd "")
  SUPPRESS_TMUX_STARTUP_HOOK=$(cfg suppress_tmux_startup_hook "true")

  DEFAULT_BASE=$(git -C "$REPO_ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || true)
  BASE_BRANCH=$(cfg base_branch "${DEFAULT_BASE:-main}")

  # Absolute/shared roots are nested under the repo name to avoid collisions.
  case "$RAW_WT_DIR" in
    '~'/*) WT_ROOT="$HOME/${RAW_WT_DIR#'~/'}"/"$REPO_SAFE_NAME" ;;
    /*)    WT_ROOT="$RAW_WT_DIR/$REPO_SAFE_NAME" ;;
    *)     WT_ROOT="$REPO_ROOT/$RAW_WT_DIR" ;;
  esac
}

