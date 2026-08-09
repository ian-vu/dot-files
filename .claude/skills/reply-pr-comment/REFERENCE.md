# Reference: PR comment reply mechanics

All endpoints verified against the GitHub REST + GraphQL API (2026) via `gh`.

## Detect the current PR + repo

```bash
gh pr view --json number,url,headRefName,baseRefName,state
gh repo view --json owner,name -q '.owner.login + " " + .name'
```

Stop if `gh pr view` reports no PR for the current branch.

## Comment types and their reply semantics

A PR has three comment surfaces. Each replies differently — confusing them is the #1 source of failures.

1. **Review-thread (inline) comments** — comments on diff lines, grouped into threads.
   - REST list: `GET /repos/{o}/{r}/pulls/{n}/comments` (each has `id`, `in_reply_to_id`, `path`, `line`, `body`, `html_url`).
   - Reply in-thread (immediate): `POST /repos/{o}/{r}/pulls/{n}/comments` with `body` + `in_reply_to` (the **root** comment's numeric id). No `path`/`line`/`commit_id` needed — `in_reply_to` selects the thread.
   - GraphQL view (resolved/outdated + node ids): the `reviewThreads` connection.

2. **Issue (general) comments** — top-level conversation.
   - `GET /repos/{o}/{r}/issues/{n}/comments`.
   - Reply = post a new issue comment: `POST /repos/{o}/{r}/issues/{n}/comments` (`gh pr comment`). Posts **immediately**; there is no thread/draft.

3. **Reviews** — review summaries with state (`COMMENTED`, `APPROVED`, `CHANGES_REQUESTED`, `PENDING`).
   - `GET /repos/{o}/{r}/pulls/{n}/reviews`. `PENDING` = draft owned by its author.

## The `in_reply_to` gotcha (422)

`POST /repos/{o}/{r}/pulls/{n}/comments` accepts a reply via `in_reply_to` as a **number**.

- `gh api -f in_reply_to=123` -> sends the string `"123"` -> 422:
  ```
  "in_reply_to" is not a number.
  "in_reply_to" is not a permitted key.   # oneOf subschema mismatch
  ```
- `gh api -F in_reply_to=123` -> typed integer -> 201. **Always use `-F`.**

`-f` = string field; `-F` = typed field (numbers/bools/JSON).

## Reply to a review thread (immediate)

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments \
  -F in_reply_to=<root_comment_id> \
  -f body="Addressed in <sha>: <summary>" \
  --jq '{id, url: .html_url}'
```

`in_reply_to` should be the **root** comment id of the thread (replying to a non-root comment still appends to the thread, but the root is unambiguous). Get it from the `discussion_r<id>` URL or:

```bash
gh api repos/<o>/<r>/pulls/<n>/comments --jq '.[] | {id, in_reply_to_id, path, line, user: .user.login, body: .body[0:80]}'
```

## Post a top-level PR comment

```bash
gh pr comment <n> --body "..."
# or
gh api -X POST repos/<o>/<r>/issues/<n>/comments -f body="..."
```

Use this for general replies and for **@mentioning a bot** to request a re-review.

## Request a re-review from a review bot

`POST .../requested_reviewers` (and `gh pr edit --request-reviewer`) **cannot request reviews from bots** — GitHub returns 200 with `requested_reviewers: []` (silently ignored). Bots are triggered by a mention comment.

### Find the bot's trigger

External review bots (Token Factory / hubert-code-surgeon, etc.) print their re-review invocation in their **verdict/summary comment footer**. Fetch bot comments and read the footer:

```bash
gh api repos/<o>/<r>/issues/<n>/comments --jq '.[] | select(.user.login|test("[bot]$")) | .body'
```

Look for text like "To re-review, mention @hubert-code-surgeon". Some bots use a slash command (`/review`) or a label instead — check `.github/` and the bot's footer. (The `@claude` GitHub Actions bot triggers on `issue_comment`/`pull_request_review_comment` via `.github/workflows/claude.yml`; that is a different mechanism from external Temporal-based bots.)

### Trigger the re-review

Post a top-level PR comment mentioning the bot. Use the `@<name>[bot]` form (GitHub's mentionable form for bot accounts); it contains `@<name>` as a substring so substring-matchers also fire:

```bash
gh pr comment <n> --body "@<bot-name>[bot] re-review please - pushed \`<sha>\`: <one-line summary>"
```

If the bot auto-reviews on `synchronize` (push), a push may already trigger it — but an explicit mention is reliable.

## Draft replies (optional, batched for user to submit)

Only for **inline review-thread comments**. Queues replies into one **PENDING** review the user submits from the PR UI. (The triage side — deciding which comments to draft replies for — lives in `address-pr-comments`.)

1. Create a pending review (omit `event`):
   ```bash
   gh api --method POST repos/<o>/<r>/pulls/<n>/reviews --input - <<<'{"body":"Replies (draft)"}'
   # -> { "id": <review_id>, "node_id": "<review_node_id>", "state": "PENDING" }
   ```
2. Add each reply via GraphQL, replying to the **root** comment's **node id** (GraphQL id, not REST database id):
   ```bash
   gh api graphql -f query='mutation($r: ID!, $p: ID!, $b: String!){
     addPullRequestReviewComment(input:{pullRequestReviewId:$r, inReplyTo:$p, body:$b}){
       comment{ id databaseId }
     }}' -F r=<review_node_id> -F p=<root_comment_node_id> -F b="..."
   ```
3. User submits from "Files changed", or you submit:
   ```bash
   gh api --method POST repos/<o>/<r>/pulls/<n>/reviews/<review_id>/events --input - <<<'{"event":"COMMENT"}'
   ```
   Don't submit unless asked. Cleanup: `gh api --method DELETE repos/<o>/<r>/pulls/<n>/reviews/<review_id>`.

## Build a commit URL for the reply body

The reply should link the fix commit so reviewers can open the diff. Build it locally from the full SHA (it 404s on github.com until pushed, but include it anyway):

```bash
owner_repo=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
commit_url="https://github.com/${owner_repo}/commit/$(git rev-parse <short_hash>)"
```

## Resolving a thread

GraphQL `resolveReviewThread` (use the thread's `id` from `reviewThreads`, not a comment id):

```bash
gh api graphql -f query='mutation($t: ID!){ resolveReviewThread(input:{threadId:$t}){ thread{ isResolved } } }' -F t=<thread_node_id>
```

Only resolve when the user explicitly asks.

## Troubleshooting

- **422 "in_reply_to is not a number"** — used `-f`; switch to `-F in_reply_to=<id>`.
- **422 "No subschema in oneOf matched / positioning wasn't supplied"** — same root cause: `in_reply_to` arrived as a string so the reply subschema didn't match. Use `-F`.
- **`json.decoder.JSONDecodeError: Extra data`** when piping `gh api` — output had trailing non-JSON (warnings, multiple objects). Use `--jq '{...}'` to project a single object, or `2>&1 | head` to inspect; don't pipe raw `gh api` into `jq` without `--jq`.
- **"(no output)" after a POST** — stderr was swallowed by `2>/dev/null`. Re-run without it; verify by re-listing the thread (`select(.in_reply_to_id == <id>)`).
- **`requested_reviewers: []` after requesting a bot** — expected; bots can't be requested via the reviewers API. Use a mention comment.
- **Bot didn't re-review after mention** — confirm the exact trigger from the bot's footer; some bots need a slash command or label, and some only run on `synchronize`/`ready_for_review`.
- **Reply posted but you don't see it** — you may be filtering by the wrong id. List with `select(.in_reply_to_id == <root_id>)`; replies carry `in_reply_to_id` pointing at the root, not the comment you replied to.
