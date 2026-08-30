# worktrees.bash: wt helper functions split out for maintainability.

worktree_records() {
  [ -d "$WT_ROOT" ] || return 0
  find "$WT_ROOT" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort | while IFS= read -r path; do
    local dir branch merged
    dir=$(basename "$path")
    branch=$(git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    merged=false
    if [ -n "$branch" ] && is_merged "$branch"; then
      merged=true
    fi
    printf '%s\t%s\t%s\t%s\n' "$dir" "$branch" "$merged" "$path"
  done
}

worktrees_list_cmd() {
  local repo="" merged=false format="plain"
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      --merged) merged=true; shift ;;
      --format) format="$2"; shift 2 ;;
      *) die "unknown worktrees list option: $1" ;;
    esac
  done
  load_context "$repo"

  case "$format" in
    plain)
      worktree_records | while IFS=$'\t' read -r dir branch is_merged_flag path; do
        if [ "$merged" = true ] && [ "$is_merged_flag" != true ]; then
          continue
        fi
        echo "$dir"
      done
      ;;
    fzf)
      worktree_records | while IFS=$'\t' read -r dir branch is_merged_flag path; do
        if [ "$merged" = true ] && [ "$is_merged_flag" != true ]; then
          continue
        fi
        if [ "$is_merged_flag" = true ]; then
          echo " $dir"
        else
          echo "  $dir"
        fi
      done
      ;;
    json)
      worktree_records | python3 -c 'import json,sys
items=[]
for line in sys.stdin:
    dir_, branch, merged, path = line.rstrip("\n").split("\t", 3)
    items.append({"worktree_dir": dir_, "branch": branch, "merged": merged == "true", "worktree_path": path})
print(json.dumps(items))'
      ;;
    *) die "unknown format: $format" ;;
  esac
}

prepare_worktree_parent() {
  case "$RAW_WT_DIR" in
    '~'/*|/*)
      mkdir -p "$WT_ROOT"
      ;;
    *)
      mkdir -p "$WT_ROOT"
      local exclude_file="$REPO_ROOT/.git/info/exclude"
      # Hide the relative worktree container from git status without changing tracked .gitignore.
      if [ -f "$exclude_file" ] && ! grep -qxF "$RAW_WT_DIR" "$exclude_file"; then
        echo "$RAW_WT_DIR" >> "$exclude_file"
      fi
      ;;
  esac
}

reject_unsupported_url_input() {
  local value="$1"
  case "$value" in
    http://*|https://*)
      case "$value" in
        https://github.com/*/pull/*|http://github.com/*/pull/*) ;;
        *) die "unsupported URL for worktree branch: $value (pass a branch name, or a GitHub PR URL)" ;;
      esac
      ;;
  esac
}

validate_branch_name() {
  local branch="$1"
  git check-ref-format --branch "$branch" >/dev/null 2>&1 \
    || die "invalid branch name: $branch"
  case "$branch" in
    -*) die "invalid branch name: $branch" ;;
  esac
}

validate_worktree_dir() {
  case "$WORKTREE_DIR" in
    ""|.|..|*:*|*" "*|*"${TAB:-$'\t'}"*) die "invalid worktree directory name derived from branch: $WORKTREE_DIR" ;;
  esac
}

validate_session_name() {
  # Tmux targets use ':' as a pane/window separator, and this pass-through value
  # is parsed as a single shell/tmux argument by wrapper scripts.
  case "$1" in
    ""|*:*|*[[:space:]]*) die "invalid tmux session name (must be non-empty and cannot contain whitespace or ':')" ;;
  esac
}

remote_tracking_branch_exists() {
  local branch="$1"
  git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$branch"
}

fetch_pr_head() {
  local remote_ref="$PR_SOURCE_REF" fetched_oid
  # A PR URL identifies a commit, not just a branch name. Refresh the source
  # branch and verify that it still points at the commit gh resolved.
  git -C "$REPO_ROOT" fetch "$PR_SOURCE_REMOTE" "$BRANCH" --quiet \
    || die "failed to fetch PR branch '$BRANCH' from $PR_SOURCE_REMOTE"
  fetched_oid=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "$remote_ref^{commit}") \
    || die "fetched PR branch is unavailable: $remote_ref"
  [ "$fetched_oid" = "$PR_HEAD_OID" ] \
    || die "PR head changed while fetching $BRANCH; paste the URL again"
}

sync_local_pr_branch_to_head() {
  local local_oid
  local_oid=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$BRANCH") \
    || return 0
  [ "$local_oid" = "$PR_HEAD_OID" ] && return 0
  git -C "$REPO_ROOT" merge-base --is-ancestor "$local_oid" "$PR_HEAD_OID" \
    || die "local branch '$BRANCH' diverges from the pasted PR URL"
  git -C "$REPO_ROOT" branch -f "$BRANCH" "$PR_HEAD_OID" \
    || die "cannot fast-forward local branch '$BRANCH' to the pasted PR URL"
}

sync_pr_worktree_to_head() {
  local current_oid
  current_oid=$(git -C "$WORKTREE_PATH" rev-parse --verify --quiet HEAD) \
    || die "cannot read worktree HEAD: $WORKTREE_PATH"
  [ "$current_oid" = "$PR_HEAD_OID" ] && return 0
  [ -z "$(git -C "$WORKTREE_PATH" status --porcelain)" ] \
    || die "worktree '$WORKTREE_PATH' has changes and is behind the pasted PR URL"
  git -C "$WORKTREE_PATH" merge-base --is-ancestor "$current_oid" "$PR_HEAD_OID" \
    || die "worktree '$WORKTREE_PATH' diverges from the pasted PR URL"
  git -C "$WORKTREE_PATH" merge --ff-only "$PR_HEAD_OID" --quiet \
    || die "cannot fast-forward worktree to the pasted PR URL"
}

checked_out_worktree_path_for_branch() {
  local branch="$1" target line path=""
  target="refs/heads/$branch"
  # Git refuses to add a worktree for a branch that is already checked out.
  # Reuse that checkout instead so selecting the current branch from tmux still
  # opens a session rather than surfacing a transient git error in the popup.
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      worktree\ *) path="${line#worktree }" ;;
      branch\ *)
        if [ "${line#branch }" = "$target" ]; then
          printf '%s\n' "$path"
          return 0
        fi
        ;;
    esac
  done < <(git -C "$REPO_ROOT" worktree list --porcelain)
  return 1
}

resolve_branch_strategy() {
  # Existing local branches fast-forward to their origin upstream so worktrees
  # always reflect the latest pushed commit rather than a stale local ref.
  # --fetch still matters for branches that exist on origin but were never
  # fetched locally (no cached remote-tracking ref to detect).
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    if remote_tracking_branch_exists "$BRANCH"; then
      STRATEGY="local_with_remote"
    else
      STRATEGY="local"
    fi
  elif remote_tracking_branch_exists "$BRANCH"; then
    STRATEGY="remote"
  elif [ "${FETCH_BEFORE_ADD:-false}" = true ] \
    && git -C "$REPO_ROOT" ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    STRATEGY="remote"
  else
    STRATEGY="new"
  fi
}

resolve_base_ref() {
  local source="$1"
  BASE_REF=""

  if git -C "$REPO_ROOT" rev-parse --verify --quiet "$source^{commit}" >/dev/null; then
    BASE_REF="$source"
    return 0
  fi

  if [[ "$source" == origin/* ]]; then
    local remote_branch="${source#origin/}"
    git -C "$REPO_ROOT" fetch origin "$remote_branch:refs/remotes/origin/$remote_branch" --quiet \
      || die "base ref not found: $source"
    git -C "$REPO_ROOT" rev-parse --verify --quiet "$source^{commit}" >/dev/null \
      || die "base ref not found: $source"
    BASE_REF="$source"
    return 0
  fi

  if git -C "$REPO_ROOT" ls-remote --exit-code --heads origin "$source" >/dev/null 2>&1; then
    git -C "$REPO_ROOT" fetch origin "$source:refs/remotes/origin/$source" --quiet \
      || die "failed to fetch base branch: origin/$source"
    BASE_REF="origin/$source"
    return 0
  fi

  die "base ref not found locally or on origin: $source"
}

fetch_for_strategy() {
  case "$STRATEGY" in
    explicit_base)
      resolve_base_ref "$BASE_SOURCE"
      ;;
    local_with_remote)
      git -C "$REPO_ROOT" fetch origin "$BRANCH" --quiet || true
      git -C "$REPO_ROOT" branch --set-upstream-to="origin/$BRANCH" "$BRANCH" >/dev/null 2>&1 || true
      # Fast-forward only: move the local ref to origin when local is an
      # ancestor of origin. Never force-update a diverged branch, which would
      # discard unpushed local commits; leave it as-is and still open the worktree.
      if git -C "$REPO_ROOT" merge-base --is-ancestor "$BRANCH" "origin/$BRANCH" >/dev/null 2>&1; then
        git -C "$REPO_ROOT" branch -f "$BRANCH" "origin/$BRANCH" >/dev/null 2>&1 || true
      fi
      ;;
    remote)
      # Refresh origin refs so the new worktree branches off the latest pushed
      # commit instead of a stale cached remote-tracking ref.
      git -C "$REPO_ROOT" fetch origin "$BRANCH" --quiet || true
      ;;
    new)
      if [ "$LOCAL_BASE" = true ]; then
        # The tmux workflow creates immediately from the local base and syncs the
        # new branch after its session starts, so the popup does not wait on I/O.
        git -C "$REPO_ROOT" rev-parse --verify --quiet "$BASE_BRANCH^{commit}" >/dev/null \
          || die "local base branch not found: $BASE_BRANCH"
      else
        # Refresh the configured base before creating a branch so origin/<base>
        # represents the latest pushed commit rather than a cached local ref.
        git -C "$REPO_ROOT" fetch origin "$BASE_BRANCH" --quiet \
          || die "failed to fetch base branch: origin/$BASE_BRANCH"
      fi
      ;;
  esac
}

create_worktree_for_strategy() {
  case "$STRATEGY" in
    explicit_base)
      git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" -b "$BRANCH" --no-track "$BASE_REF" --quiet
      ;;
    local|local_with_remote)
      git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" "$BRANCH" --quiet
      ;;
    remote)
      git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" -b "$BRANCH" --track "origin/$BRANCH" --quiet
      ;;
    new)
      local base_ref="origin/$BASE_BRANCH"
      [ "$LOCAL_BASE" = true ] && base_ref="$BASE_BRANCH"
      git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" -b "$BRANCH" --no-track "$base_ref" --quiet
      ;;
  esac
}

validate_existing_worktree() {
  # A directory name alone is not proof of a reusable worktree: stale checkouts
  # and slash-to-dash branch collisions must fail before setup changes files.
  local existing_common_dir repo_common_dir existing_branch
  existing_common_dir=$(git -C "$WORKTREE_PATH" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
    || die "path exists but is not a valid git worktree: $WORKTREE_PATH; move it aside or remove it, then retry"
  repo_common_dir=$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)
  [ "$existing_common_dir" = "$repo_common_dir" ] \
    || die "path belongs to a different git repository: $WORKTREE_PATH"

  existing_branch=$(git -C "$WORKTREE_PATH" symbolic-ref --quiet --short HEAD 2>/dev/null) \
    || die "existing worktree is not on a branch: $WORKTREE_PATH"
  [ "$existing_branch" = "$BRANCH" ] \
    || die "existing worktree at $WORKTREE_PATH checks out '$existing_branch', not '$BRANCH'"
}

setup_files() {
  COPIED=0
  LINKED=0

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    local src="$REPO_ROOT/$file" dest="$WORKTREE_PATH/$file"
    if [ -f "$src" ]; then
      mkdir -p "$(dirname "$dest")"
      cp "$src" "$dest"
      COPIED=$((COPIED + 1))
    fi
  done < <(cfg_array copy_paths)

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    file="${file%/}"
    local src="$REPO_ROOT/$file" dest="$WORKTREE_PATH/$file"
    if [ -e "$src" ]; then
      mkdir -p "$(dirname "$dest")"
      ln -sf "$src" "$dest"
      LINKED=$((LINKED + 1))
    fi
  done < <(cfg_array symlinks)

  local main_exclude="$REPO_ROOT/.git/info/exclude"
  if [ -f "$main_exclude" ]; then
    local wt_git_dir
    wt_git_dir=$(git -C "$WORKTREE_PATH" rev-parse --git-dir)
    mkdir -p "$wt_git_dir/info"
    ln -sf "$main_exclude" "$wt_git_dir/info/exclude"
  fi
}

emit_add_json() {
  CREATED_VALUE="$1" COPIED_VALUE="$COPIED" LINKED_VALUE="$LINKED" CONFIG_CREATED_VALUE="$CONFIG_CREATED" \
  REPO_ROOT_VALUE="$REPO_ROOT" REPO_SAFE_NAME_VALUE="$REPO_SAFE_NAME" BRANCH_VALUE="$BRANCH" \
  WORKTREE_DIR_VALUE="$WORKTREE_DIR" WORKTREE_PATH_VALUE="$WORKTREE_PATH" RAW_WT_DIR_VALUE="$RAW_WT_DIR" \
  STARTUP_CMD_VALUE="$STARTUP_CMD" SUPPRESS_VALUE="$SUPPRESS_TMUX_STARTUP_HOOK" BASE_BRANCH_VALUE="$BASE_BRANCH" \
  BASE_SOURCE_VALUE="${BASE_SOURCE:-}" BASE_REF_VALUE="${BASE_REF:-}" SESSION_NAME_VALUE="${SESSION_NAME:-}" \
  BASE_SYNC_PENDING_VALUE="$BASE_SYNC_PENDING" BASE_SYNC_BRANCH_VALUE="$BASE_SYNC_BRANCH" \
  python3 -c 'import json, os
payload = {
  "repo_root": os.environ["REPO_ROOT_VALUE"],
  "repo_safe_name": os.environ["REPO_SAFE_NAME_VALUE"],
  "branch": os.environ["BRANCH_VALUE"],
  "base_branch": os.environ["BASE_BRANCH_VALUE"],
  "worktree_dir": os.environ["WORKTREE_DIR_VALUE"],
  "worktree_path": os.environ["WORKTREE_PATH_VALUE"],
  "worktree_root": os.environ["RAW_WT_DIR_VALUE"],
  "startup_cmd": os.environ["STARTUP_CMD_VALUE"],
  "suppress_tmux_startup_hook": os.environ["SUPPRESS_VALUE"].lower() == "true",
  "session_name": os.environ["SESSION_NAME_VALUE"],
  "base_sync_pending": os.environ["BASE_SYNC_PENDING_VALUE"] == "true",
  "base_sync_branch": os.environ["BASE_SYNC_BRANCH_VALUE"],
  "created": os.environ["CREATED_VALUE"] == "true",
  "config_created": os.environ["CONFIG_CREATED_VALUE"] == "true",
  "copied": int(os.environ["COPIED_VALUE"]),
  "linked": int(os.environ["LINKED_VALUE"]),
}
if os.environ["BASE_SOURCE_VALUE"]:
  payload["base_source"] = os.environ["BASE_SOURCE_VALUE"]
  payload["base_ref"] = os.environ["BASE_REF_VALUE"]
print(json.dumps(payload))'
}

github_repo_slug_from_remote() {
  local remote="$1" path=""
  case "$remote" in
    git@github.com:*) path="${remote#git@github.com:}" ;;
    ssh://git@github.com/*) path="${remote#ssh://git@github.com/}" ;;
    https://github.com/*|http://github.com/*) path="${remote#*github.com/}" ;;
    *) return 1 ;;
  esac
  path="${path%.git}"
  path="${path%/}"
  printf '%s\n' "$path"
}

validate_pr_repo() {
  local url="$1" url_repo origin_url origin_repo
  url_repo="${url#*github.com/}"
  url_repo="${url_repo%%/pull/*}"
  origin_url=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)
  origin_repo=$(github_repo_slug_from_remote "$origin_url" || true)
  if [ -n "$origin_repo" ] && [ "$url_repo" != "$origin_repo" ]; then
    die "PR URL repository '$url_repo' does not match origin '$origin_repo'"
  fi
}

# Resolve a GitHub PR URL (e.g. https://github.com/owner/repo/pull/123 or .../pull/123/files)
# to the exact head commit via gh. For cross-repository PRs (forks), register a remote and
# fetch the head ref so the regular branch strategy can find it.
resolve_pr_url() {
  local url="$1"
  require_cmd gh
  validate_pr_repo "$url"
  local json head_ref head_oid is_cross fork_owner fork_repo
  json=$(gh pr view "$url" --json headRefName,headRefOid,isCrossRepository,headRepositoryOwner,headRepository 2>/dev/null) \
    || die "failed to resolve PR url via gh: $url"
  head_ref=$(printf '%s' "$json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["headRefName"])')
  head_oid=$(printf '%s' "$json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["headRefOid"])')
  [ -n "$head_ref" ] || die "could not resolve branch from PR url: $url"
  [ -n "$head_oid" ] || die "could not resolve commit from PR url: $url"
  PR_HEAD_OID="$head_oid"
  PR_SOURCE_REMOTE="origin"
  PR_SOURCE_REF="origin/$head_ref"
  is_cross=$(printf '%s' "$json" | python3 -c 'import json,sys;print("true" if json.load(sys.stdin)["isCrossRepository"] else "false")')
  if [ "$is_cross" = true ]; then
    fork_owner=$(printf '%s' "$json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["headRepositoryOwner"]["login"])')
    fork_repo=$(printf '%s' "$json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["headRepository"]["name"])')
    local remote="pr-$fork_owner"
    if ! git -C "$REPO_ROOT" remote get-url "$remote" >/dev/null 2>&1; then
      info "adding fork remote '$remote' for $fork_owner/$fork_repo"
      git -C "$REPO_ROOT" remote add "$remote" "https://github.com/$fork_owner/$fork_repo.git"
    fi
    PR_SOURCE_REMOTE="$remote"
    PR_SOURCE_REF="$remote/$head_ref"
  fi
  BRANCH="$head_ref"
}

worktrees_add_cmd() {
  local repo="" format="text"
  BASE_SOURCE=""
  BASE_REF=""
  SESSION_NAME=""
  FETCH_BEFORE_ADD=false
  LOCAL_BASE=false
  [ $# -gt 0 ] || die "branch required"
  BRANCH="$1"; shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) repo="${2:-}"; [ -n "$repo" ] || die "--repo requires a path"; shift 2 ;;
      --format) format="${2:-}"; [ -n "$format" ] || die "--format requires a value"; shift 2 ;;
      --base) BASE_SOURCE="${2:-}"; [ -n "$BASE_SOURCE" ] || die "--base requires a ref"; shift 2 ;;
      --session|--session-name) SESSION_NAME="${2:-}"; [ -n "$SESSION_NAME" ] || die "$1 requires a name"; shift 2 ;;
      --fetch) FETCH_BEFORE_ADD=true; shift ;;
      --local-base) LOCAL_BASE=true; shift ;;
      *) die "unknown worktrees add option: $1" ;;
    esac
  done

  BRANCH="${BRANCH#"${BRANCH%%[![:space:]]*}"}"
  BRANCH="${BRANCH%"${BRANCH##*[![:space:]]}"}"
  BASE_SOURCE="${BASE_SOURCE#"${BASE_SOURCE%%[![:space:]]*}"}"
  BASE_SOURCE="${BASE_SOURCE%"${BASE_SOURCE##*[![:space:]]}"}"
  SESSION_NAME="${SESSION_NAME#"${SESSION_NAME%%[![:space:]]*}"}"
  SESSION_NAME="${SESSION_NAME%"${SESSION_NAME##*[![:space:]]}"}"
  PR_HEAD_OID=""
  PR_SOURCE_REMOTE=""
  PR_SOURCE_REF=""
  [ -n "$BRANCH" ] || die "branch required"
  [ -z "$SESSION_NAME" ] || validate_session_name "$SESSION_NAME"
  [ -z "$BASE_SOURCE" ] || [ "$LOCAL_BASE" = false ] || die "--local-base cannot be combined with --base"
  reject_unsupported_url_input "$BRANCH"
  case "$BRANCH" in
    https://github.com/*/pull/*|http://github.com/*/pull/*) ;;
    *) validate_branch_name "$BRANCH" ;;
  esac

  if [ -z "$repo" ]; then
    repo=$(repo_root .) || die "not inside a git worktree; pass --repo"
  fi
  REPO_ROOT=$(repo_root "$repo") || die "not a git repository: $repo"
  ensure_config "$REPO_ROOT"
  load_context "$REPO_ROOT"

  # Accept a GitHub PR URL in place of a branch name; resolve to the head ref via gh.
  case "$BRANCH" in
    https://github.com/*/pull/*|http://github.com/*/pull/*)
      info "resolving PR url via gh"
      resolve_pr_url "$BRANCH"
      validate_branch_name "$BRANCH"
      fetch_pr_head
      if [ "$PR_SOURCE_REMOTE" != origin ] \
        && ! git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        # Fork PRs need a local branch so the regular worktree strategy can
        # create the checkout from the fork head instead of the base branch.
        git -C "$REPO_ROOT" branch "$BRANCH" "$PR_SOURCE_REF" \
          || die "failed to create local branch for PR URL: $BRANCH"
      fi
      info "resolved to branch '$BRANCH' at $PR_HEAD_OID"
      ;;
    *)
      validate_branch_name "$BRANCH"
      ;;
  esac

  WORKTREE_DIR="${BRANCH//\//-}"
  validate_worktree_dir
  WORKTREE_PATH="$WT_ROOT/$WORKTREE_DIR"
  CREATED=false
  COPIED=0
  LINKED=0
  BASE_SYNC_PENDING=false
  BASE_SYNC_BRANCH=""
  local expected_worktree_path="$WORKTREE_PATH" existing_checkout="" should_setup_files=true

  info "preparing worktree '$BRANCH'"
  if [ ! -d "$WORKTREE_PATH" ]; then
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
      existing_checkout=$(checked_out_worktree_path_for_branch "$BRANCH" || true)
    fi
    if [ -n "$existing_checkout" ] && [ ! -d "$existing_checkout" ]; then
      info "pruning stale worktree record at $existing_checkout"
      git -C "$REPO_ROOT" worktree prune
      existing_checkout=""
    fi
    if [ -n "$existing_checkout" ]; then
      WORKTREE_PATH="$existing_checkout"
      should_setup_files=false
      info "branch already checked out at $WORKTREE_PATH"
    else
      prepare_worktree_parent
      if [ -n "$PR_HEAD_OID" ]; then
        sync_local_pr_branch_to_head
      fi
      info "resolving branch strategy"
      if [ -n "$BASE_SOURCE" ]; then
        STRATEGY="explicit_base"
      else
        resolve_branch_strategy
      fi
      if [ "$STRATEGY" != "local" ]; then
        case "$STRATEGY" in
          explicit_base) info "resolving base '$BASE_SOURCE'" ;;
          local_with_remote) info "fast-forwarding '$BRANCH' to origin" ;;
          remote) info "fetching '$BRANCH' from origin" ;;
          new)
            if [ "$LOCAL_BASE" = true ]; then
              info "using local base '$BASE_BRANCH' (fetch deferred to session)"
              BASE_SYNC_PENDING=true
              BASE_SYNC_BRANCH="$BASE_BRANCH"
            else
              info "fetching base '$BASE_BRANCH'"
            fi
            ;;
        esac
        fetch_for_strategy
      fi
      info "creating worktree at $WORKTREE_PATH"
      create_worktree_for_strategy
      CREATED=true
    fi
  else
    validate_existing_worktree
    info "worktree already exists at $WORKTREE_PATH"
  fi

  if [ -n "$PR_HEAD_OID" ]; then
    sync_pr_worktree_to_head
  fi

  if [ "$should_setup_files" = true ]; then
    info "copying and linking configured files"
    setup_files
  else
    info "skipping file setup for existing checkout outside $expected_worktree_path"
  fi

  case "$format" in
    text) printf '%s\n' "$WORKTREE_PATH" ;;
    json) emit_add_json "$CREATED" ;;
    *) die "unknown format: $format" ;;
  esac
}

resolve_worktree_input_path() {
  local input="$1"
  case "$input" in
    '~'/*) WORKTREE_PATH="$HOME/${input#'~/'}"; WORKTREE_DIR=$(basename "$WORKTREE_PATH") ;;
    /*)    WORKTREE_PATH="$input"; WORKTREE_DIR=$(basename "$WORKTREE_PATH") ;;
    *)     WORKTREE_DIR="$input"; WORKTREE_PATH="$WT_ROOT/$WORKTREE_DIR" ;;
  esac
}

worktrees_rm_cmd() {
  local repo=""
  [ $# -gt 0 ] || die "worktree required"
  local input="$1"; shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      *) die "unknown worktrees rm option: $1" ;;
    esac
  done
  load_context "$repo"
  resolve_worktree_input_path "$input"

  if [ -d "$WORKTREE_PATH" ]; then
    git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_PATH" 2>/dev/null || rm -rf "$WORKTREE_PATH"
    git -C "$REPO_ROOT" worktree prune
  fi
  printf '%s\n' "$WORKTREE_PATH"
}

worktrees_cmd() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    ""|help|--help|-h) help_worktrees ;;
    list) worktrees_list_cmd "$@" ;;
    add) worktrees_add_cmd "$@" ;;
    rm|remove) worktrees_rm_cmd "$@" ;;
    *) die "unknown worktrees command: $sub" ;;
  esac
}

