# Shared constants and utility helpers for wt. Kept separate so command modules stay focused.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wt"
REPO_CACHE="$CACHE_DIR/repos"
PINS_FILE="$CACHE_DIR/pinned_repos"
TEMPLATE="$HOME/.config/ivu/template.yml"
PIN_ICON="📌"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_GREEN=$'\033[1;32m'
  C_ORANGE=$'\033[38;2;255;150;108m'
  C_BLUE=$'\033[1;34m'
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_GREEN=""
  C_ORANGE=""
  C_BLUE=""
fi

die() {
  echo "wt: $*" >&2
  exit 1
}

info() {
  # Keep command stdout machine-readable; progress for long tasks goes to stderr.
  [ -n "${WT_QUIET:-}" ] && return 0
  printf '%swt:%s %s\n' "$C_DIM" "$C_RESET" "$*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

json_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))'
}

json_array() {
  python3 -c 'import json,sys; print(json.dumps([line.rstrip("\n") for line in sys.stdin]))'
}

safe_name() {
  local name="$1"
  name="${name//./-}"
  name="${name//:/-}"
  printf '%s\n' "$name"
}

