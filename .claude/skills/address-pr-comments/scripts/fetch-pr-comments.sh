#!/usr/bin/env bash
# Fetch and summarize all comments on the current (or given) pull request.
#
# Prints a markdown triage report to stdout and writes a full JSON object
# (with GraphQL node ids needed for draft replies) to a temp file, printing
# that path as the last line prefixed with "JSON:".
#
# Usage: fetch-pr-comments.sh [PR_NUMBER]
#
# Requires: gh (authenticated), jq.
set -euo pipefail

PR_NUMBER="${1:-}"
if [[ -z "$PR_NUMBER" ]]; then
  PR_NUMBER="$(gh pr view --json number -q .number 2>/dev/null || true)"
fi
if [[ -z "$PR_NUMBER" ]]; then
  echo "No pull request found for the current branch. Pass a PR number as \$1." >&2
  exit 1
fi

OWNER_REPO="$(gh repo view --json owner,name -q '.owner.login + " " + .name')"
OWNER="${OWNER_REPO%% *}"
REPO="${OWNER_REPO##* }"

PR_JSON="$(gh pr view "$PR_NUMBER" --json url,headRefName,baseRefName,state,title)"
PR_URL="$(printf '%s' "$PR_JSON" | jq -r .url)"
PR_TITLE="$(printf '%s' "$PR_JSON" | jq -r .title)"
PR_STATE="$(printf '%s' "$PR_JSON" | jq -r .state)"

# --- Review threads via GraphQL (resolved/outdated status + node ids) ---
THREADS_QUERY='
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 50) {
            nodes {
              databaseId
              id
              body
              url
              author { login }
              createdAt
            }
          }
        }
      }
    }
  }
}'

THREADS_RAW="$(gh api graphql -f query="$THREADS_QUERY" \
  -F owner="$OWNER" -F name="$REPO" -F number="$PR_NUMBER")"

# --- Issue (general) comments + reviews via REST ---
ISSUE_COMMENTS="$(gh api "repos/$OWNER/$REPO/issues/$PR_NUMBER/comments?per_page=100" \
  --jq '[.[] | {id, author: .user.login, body, html_url, created_at}]' 2>/dev/null || echo '[]')"

REVIEWS="$(gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews?per_page=100" \
  --jq '[.[] | {id, author: .user.login, state, body, html_url, submitted_at}]' 2>/dev/null || echo '[]')"

# --- Assemble full JSON for machine use (replies need node ids) ---
FULL_JSON="$(jq -n \
  --arg pr_number "$PR_NUMBER" --arg pr_url "$PR_URL" --arg pr_title "$PR_TITLE" --arg pr_state "$PR_STATE" \
  --argjson threads "$THREADS_RAW" \
  --argjson issue_comments "$ISSUE_COMMENTS" \
  --argjson reviews "$REVIEWS" \
  '{
    pr: {number: ($pr_number|tonumber), url: $pr_url, title: $pr_title, state: $pr_state},
    review_threads: $threads.data.repository.pullRequest.reviewThreads.nodes,
    issue_comments: $issue_comments,
    reviews: $reviews
  }')"

# Flatten review threads into one row per thread (root comment) for triage.
THREADS_FLAT="$(printf '%s' "$FULL_JSON" | jq -r '
  .review_threads
  | to_entries
  | .[]
  | .key as $idx
  | .value as $t
  | ($t.comments.nodes[0]) as $root
  | {
      thread_index: $idx,
      thread_node_id: $t.id,
      is_resolved: $t.isResolved,
      is_outdated: $t.isOutdated,
      path: $t.path,
      line: $t.line,
      root_database_id: $root.databaseId,
      root_node_id: $root.id,
      root_author: $root.author.login,
      root_body: $root.body,
      root_url: $root.url,
      reply_count: (($t.comments.nodes | length) - 1)
    }')"

OUT_FILE="${TMPDIR:-/tmp}/pr-comments-${PR_NUMBER}.json"
printf '%s' "$FULL_JSON" | jq . > "$OUT_FILE"

# --- Markdown report ---
echo "## PR #$PR_NUMBER: $PR_TITLE"
echo "State: $PR_STATE  |  $PR_URL"
echo

REVIEW_COUNT="$(printf '%s' "$FULL_JSON" | jq '.review_threads | length')"
ISSUE_COUNT="$(printf '%s' "$FULL_JSON" | jq '.issue_comments | length')"
PENDING_COUNT="$(printf '%s' "$FULL_JSON" | jq '[.reviews[] | select(.state=="PENDING")] | length')"
echo "Review threads: $REVIEW_COUNT  |  General comments: $ISSUE_COUNT  |  Pending reviews (yours): $PENDING_COUNT"
echo

echo "### Review-thread (inline) comments"
if [[ "$REVIEW_COUNT" -eq 0 ]]; then
  echo "_None._"
else
  echo "| # | author | location | resolved/outdated | verdict | reason |"
  echo "|---|--------|----------|-------------------|---------|--------|"
  printf '%s' "$THREADS_FLAT" | jq -r --arg sep $'\t' '
    [(.thread_index+1|tostring), .root_author,
     (if (.path // null) then "\(.path):\(.line // "?")" else "(no file)" end),
     ([(if .is_resolved then "resolved" else empty end), (if .is_outdated then "outdated" else empty end)] | join("/")),
     "", ""] | join($sep)'
  # The verdict/reason columns are left blank for the agent to fill in.
fi
echo

echo "### Review-thread details (for commit messages + draft replies)"
if [[ "$REVIEW_COUNT" -gt 0 ]]; then
  printf '%s' "$THREADS_FLAT" | jq -r '
    "#### Thread \(.thread_index+1) — \(.root_author) — \(.root_url)",
    "- file: \(.path // "?"):\(.line // "?")",
    "- resolved: \(.is_resolved)  outdated: \(.is_outdated)  replies: \(.reply_count)",
    "- root_node_id: \(.root_node_id)   (use as inReplyTo for draft replies)",
    "- root_database_id: \(.root_database_id)",
    "```",
    "\(.root_body // "")",
    "```"'
  echo
fi

echo "### General (issue) comments"
if [[ "$ISSUE_COUNT" -eq 0 ]]; then
  echo "_None._"
else
  printf '%s' "$FULL_JSON" | jq -r '.issue_comments[] | "- [\( .id )] \( .author ): \( .html_url )\n```\n\( .body )\n```\n"'
fi

echo "### Reviews"
if [[ "$(printf '%s' "$FULL_JSON" | jq '.reviews | length')" -eq 0 ]]; then
  echo "_None._"
else
  printf '%s' "$FULL_JSON" | jq -r '.reviews[] | "- [\( .state )] \( .author ): \( .html_url )\n  \( .body | if . == "" then "(no summary body)" else . end )\n"'
fi

echo
echo "JSON: $OUT_FILE"
