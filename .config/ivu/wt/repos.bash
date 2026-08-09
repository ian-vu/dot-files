# repos.bash: wt helper functions split out for maintainability.
# Repository discovery, cache, and pin management for the `wt repos` command.

list_repo_dirs() {
  local dev_dir="$1"
  [ -d "$dev_dir" ] || return 0
  find -L "$dev_dir" -mindepth 2 -maxdepth 5 -type d -exec test -e '{}/.git' \; -print -prune 2>/dev/null \
    | sed "s|^$dev_dir/||" | sort
}

refresh_repos() {
  local dev_dir="$1"
  mkdir -p "$CACHE_DIR"
  list_repo_dirs "$dev_dir" > "$REPO_CACHE"
}

ensure_repo_cache() {
  local dev_dir="$1"
  # An empty cache makes the tmux/fzf repo picker look broken; rebuild it
  # synchronously when discovery previously failed or was interrupted.
  if [ ! -s "$REPO_CACHE" ]; then
    refresh_repos "$dev_dir"
  fi
}

repos_list() {
  local dev_dir="$HOME/dev" format="plain"
  while [ $# -gt 0 ]; do
    case "$1" in
      --dev-dir) dev_dir="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      *) die "unknown repos list option: $1" ;;
    esac
  done

  local repos_tmp
  repos_tmp=$(mktemp)
  # Live discovery is fast enough and avoids tmux/fzf showing stale or empty cache contents.
  list_repo_dirs "$dev_dir" > "$repos_tmp"
  case "$format" in
    plain)
      cat "$repos_tmp"
      ;;
    json)
      cat "$repos_tmp" | json_array
      ;;
    fzf)
      # Pins are display-only ordering metadata; repository paths stay relative to dev_dir.
      if [ -f "$PINS_FILE" ]; then
        while IFS= read -r repo; do
          [ -z "$repo" ] && continue
          if grep -qxF "$repo" "$repos_tmp" 2>/dev/null; then
            echo "$PIN_ICON $repo"
          fi
        done < "$PINS_FILE"
      fi
      while IFS= read -r repo; do
        if [ -f "$PINS_FILE" ] && grep -qxF "$repo" "$PINS_FILE" 2>/dev/null; then
          continue
        fi
        echo "  $repo"
      done < "$repos_tmp"
      ;;
    *) rm -f "$repos_tmp"; die "unknown format: $format" ;;
  esac
  rm -f "$repos_tmp"
}

repos_pin_list() {
  # Pin order is user-controlled picker metadata, so read it directly rather than sorting.
  [ -f "$PINS_FILE" ] || return 0
  grep -v '^$' "$PINS_FILE" || true
}

repos_pin_toggle() {
  local repo="$1"
  [ -n "$repo" ] || die "repo required"
  repo="${repo#$PIN_ICON }"
  repo="${repo#  }"
  mkdir -p "$CACHE_DIR"
  if grep -qxF "$repo" "$PINS_FILE" 2>/dev/null; then
    grep -vxF "$repo" "$PINS_FILE" > "$PINS_FILE.tmp" || true
    mv "$PINS_FILE.tmp" "$PINS_FILE"
  else
    echo "$repo" >> "$PINS_FILE"
  fi
}

repos_cmd() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    ""|help|--help|-h) help_repos ;;
    list) repos_list "$@" ;;
    refresh)
      local dev_dir="$HOME/dev"
      while [ $# -gt 0 ]; do
        case "$1" in
          --dev-dir) dev_dir="$2"; shift 2 ;;
          *) die "unknown repos refresh option: $1" ;;
        esac
      done
      refresh_repos "$dev_dir"
      ;;
    pin)
      local pin_sub="${1:-}"; shift || true
      case "$pin_sub" in
        list) repos_pin_list ;;
        toggle) repos_pin_toggle "${1:-}" ;;
        *) die "unknown repos pin command: $pin_sub" ;;
      esac
      ;;
    *) die "unknown repos command: $sub" ;;
  esac
}
