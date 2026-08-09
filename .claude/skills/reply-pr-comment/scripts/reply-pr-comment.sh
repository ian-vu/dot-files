#!/usr/bin/env bash
# Reply to a PR review-thread (inline) comment.
#
# Encodes the one real gotcha: `in_reply_to` must be a TYPED INTEGER (`-F`),
# not a string (`-f` -> GitHub 422 "is not a number"). Also resolves the thread
# root automatically when given a reply (non-root) comment id.
#
# Usage:
#   reply-pr-comment.sh <comment_id_or_url> [body]
#   reply-pr-comment.sh <comment_id_or_url> -        # body from stdin
#   echo "body" | reply-pr-comment.sh <comment_id_or_url>
#
# <comment_id_or_url>:
#   - full URL ending in #discussion_r<ID>
#   - bare numeric review-comment id (e.g. 3592202817)
#
# Top-level issue comments (issuecomment-<id>) have no thread and cannot be
# replied to here — use `gh pr comment` for those. This script errors out with
# a hint if the id is not found among review-thread comments.
#
# Requires: gh (authenticated), jq.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <comment_id_or_url> [body|-]" >&2
  exit 1
fi

INPUT="$1"
BODY="${2:-}"

# Parse a discussion_r<id> URL down to the numeric id.
if [[ "$INPUT" =~ discussion_r([0-9]+) ]]; then
  COMMENT_ID="${BASH_REMATCH[1]}"
elif [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  COMMENT_ID="$INPUT"
else
  echo "Error: '$INPUT' is not a discussion_r<id> URL or numeric comment id." >&2
  exit 1
fi

# Resolve body: explicit arg wins; otherwise read stdin (only if not a TTY).
if [[ -n "$BODY" && "$BODY" != "-" ]]; then
  : # use BODY verbatim
else
  if [[ -t 0 ]]; then
    echo "Error: no reply body. Pass body as \$2, '-' to read stdin, or pipe it." >&2
    exit 1
  fi
  BODY="$(cat)"
fi

if [[ -z "${BODY// }" ]]; then
  echo "Error: reply body is empty." >&2
  exit 1
fi

# Resolve owner/repo + PR number from the current branch.
PR_NUMBER="$(gh pr view --json number -q .number 2>/dev/null || true)"
if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: no PR found for the current branch." >&2
  exit 1
fi
OWNER_REPO="$(gh repo view --json owner,name -q '.owner.login + "/" + .name')"

# Validate the target comment exists and is a review-thread comment.
TARGET="$(gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/comments" \
  --jq ".[] | select(.id == ${COMMENT_ID}) | {id, in_reply_to_id, user: .user.login, path, line}" 2>/dev/null || true)"
if [[ -z "$TARGET" ]]; then
  echo "Error: review comment ${COMMENT_ID} not found on PR #${PR_NUMBER} in ${OWNER_REPO}." >&2
  echo "If this is a top-level issue comment (issuecomment-<id>), it has no thread — use: gh pr comment ${PR_NUMBER} --body \"...\"" >&2
  exit 1
fi

# Reply to the thread root if this is a non-root comment, else to the comment itself.
ROOT_ID="$(printf '%s' "$TARGET" | jq -r 'if .in_reply_to_id then .in_reply_to_id else .id end')"

# Post the reply. CRITICAL: -F (typed) for in_reply_to, never -f (string -> 422).
ERR_FILE="$(mktemp)"
trap 'rm -f "$ERR_FILE"' EXIT
if ! RESULT="$(gh api -X POST "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/comments" \
  -F "in_reply_to=${ROOT_ID}" \
  -f "body=${BODY}" \
  --jq '{id, url: .html_url}' 2>"$ERR_FILE")"; then
  echo "Error: reply POST failed:" >&2
  cat "$ERR_FILE" >&2
  exit 1
fi

NEW_ID="$(printf '%s' "$RESULT" | jq -r '.id')"
NEW_URL="$(printf '%s' "$RESULT" | jq -r '.url')"
echo "Replied to comment ${COMMENT_ID} (thread root ${ROOT_ID}):"
echo "  ${NEW_URL}"
echo "  (new comment id: ${NEW_ID})"
