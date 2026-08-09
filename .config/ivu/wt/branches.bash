# branches.bash: wt helper functions split out for maintainability.

branches_cmd() {
  local repo="" fetch=false format="plain"
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) repo="$2"; shift 2 ;;
      --fetch) fetch=true; shift ;;
      --format) format="$2"; shift 2 ;;
      *) die "unknown branches option: $1" ;;
    esac
  done
  load_context "$repo"

  case "$format" in
    plain)
      if [ "$fetch" = true ]; then
        { list_branches_raw; git -C "$REPO_ROOT" fetch --all --quiet >/dev/null 2>&1 || true; list_branches_raw; } | awk '!seen[$0]++'
      else
        list_branches_raw
      fi
      ;;
    json)
      [ "$fetch" = true ] && git -C "$REPO_ROOT" fetch --all --quiet >/dev/null 2>&1 || true
      list_branches_raw | json_array
      ;;
    *) die "unknown format: $format" ;;
  esac
}

