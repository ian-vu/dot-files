# Reference: PR comment API mechanics

All endpoints below were verified against the GitHub REST + GraphQL API (2026). `gh` is used throughout.

## Detecting the current PR

```bash
gh pr view --json number,url,headRefName,baseRefName,state
gh repo view --json owner,name -q '.owner.login + " " + .name'
```

Stop if `gh pr view` reports no PR for the current branch.

## Comment types

A PR has three kinds of comments:

1. **Review-thread (inline) comments** - comments on specific diff lines, grouped into threads. Fetched via GraphQL `reviewThreads` (gives `isResolved`, `isOutdated`, thread structure, and GraphQL node ids). These are the only comments that support **draft** replies.
2. **Issue (general) comments** - top-level conversation comments. `GET /repos/{owner}/{repo}/issues/{number}/comments`. Replying posts **immediately** (`POST /repos/{owner}/{repo}/issues/{number}/comments`); there is no draft state.
3. **Reviews** - review summaries with a state (`COMMENTED`, `APPROVED`, `CHANGES_REQUESTED`, `PENDING`). `GET /repos/{owner}/{repo}/pulls/{number}/reviews`. `PENDING` reviews are drafts owned by their author; skip them when triaging unless the user asks.

Each comment/review carries an `html_url` permalink - use it verbatim in commit messages and replies.

## Draft reply flow (verified)

There is **no REST endpoint** to append a reply to an existing thread inside a pending review (`POST .../reviews/{id}/comments` returns 404). Use the GraphQL mutation instead:

1. Create a pending review (omit `event`):
   ```bash
   gh api --method POST repos/<owner>/<repo>/pulls/<n>/reviews \
     --input - <<<'{"body":"Replies to review comments (draft)"}'
   # -> { "id": <review_id>, "node_id": "<review_node_id>", "state": "PENDING", ... }
   ```
2. Add each reply to that pending review, replying to the **root** comment of the thread (`inReplyTo` must be a top-level review comment's node id; replies to replies are not supported). Include the fix commit's GitHub URL in the body so reviewers can open the diff; build it locally from the owner/repo and the commit's full SHA so it is present even before the commit is pushed (it 404s on github.com until pushed):
   ```bash
   owner_repo=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
   commit_url="https://github.com/${owner_repo}/commit/$(git rev-parse <short_hash>)"
   gh api graphql -f query='
   mutation($r: ID!, $p: ID!, $b: String!) {
     addPullRequestReviewComment(input: {pullRequestReviewId: $r, inReplyTo: $p, body: $b}) {
       comment { id databaseId }
     }
   }' -F r=<review_node_id> -F p=<root_comment_node_id> \
     -F b="Fixed in <short_hash>: <one-line summary>
${commit_url}"
   ```
3. The user edits/submits from the PR "Files changed" view, or you submit with:
   ```bash
   gh api --method POST repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>/events \
     --input - <<<'{"event":"COMMENT"}'
   ```
   Do not submit unless the user explicitly asks.

Cleanup (if you created a review by mistake):

```bash
gh api --method DELETE repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>
```

## Replying to general (issue) comments

Posts immediately, no draft:

```bash
gh api --method POST repos/<owner>/<repo>/issues/<n>/comments -f body="..."
```

## Resolving a review thread

GraphQL `resolveReviewThread` (use the thread's `id` from the `reviewThreads` connection, not a comment id):

```bash
gh api graphql -f query='mutation($t: ID!){ resolveReviewThread(input:{threadId:$t}){ thread{ isResolved } } }' -F t=<thread_node_id>
```

Only resolve when the user explicitly asks; the fetch script does not resolve.

## Fetch script notes

`scripts/fetch-pr-comments.sh` fetches up to 100 review threads (50 comments each) and the first 100 issue comments/reviews. For very large PRs it paginates review threads; if a PR exceeds these limits the script prints a warning - re-run or extend pagination in the script.

The JSON file the script writes includes, per review-thread comment: `databaseId`, `node_id` (GraphQL id, needed for `inReplyTo`), `root_node_id`, `body`, `url`, `author`, plus thread-level `isResolved`/`isOutdated`/`path`/`line`. Issue comments and reviews include their REST ids and `html_url`.
