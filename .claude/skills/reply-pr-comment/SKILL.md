---
name: reply-pr-comment
description: Reply to PR review comments (inline threads) and request re-reviews from review bots. Use when replying to a PR review comment, posting a fix-update reply in a thread, requesting a bot re-review, or parsing a discussion_r comment URL. For triaging comments and committing one fix per comment, use address-pr-comments instead.
---

# Reply to PR Comments

The **mechanics layer** for PR comments: post replies in review threads and trigger bot re-reviews. This skill does **not** triage or commit fixes — that is `address-pr-comments` (it loads comments with context and runs the one-commit-per-comment flow). Load this skill when the fix is already made (or being answered) and you need to post the reply / re-review request.

## Three reply targets — pick the right one

| Target | When | How | Posts |
|---|---|---|---|
| **Review-thread reply** | Answering inside an inline diff thread (e.g. after fixing that comment) | `POST /repos/{o}/{r}/pulls/{n}/comments` with `in_reply_to` | immediately |
| **Top-level PR comment** | General reply, or @mentioning a bot for re-review | `gh pr comment {n}` | immediately |
| **Draft review reply** | Batching replies for the user to submit from the GitHub UI | GraphQL `addPullRequestReviewComment` on a PENDING review | draft (user submits) |

`gh pr comment` is a **top-level issue comment**, never a thread reply. Don't confuse the two.

## Reply to a review-thread comment (most common)

Use the helper script — it encodes the one real gotcha (`in_reply_to` must be a **typed integer**, not a string):

```bash
bash <skill-dir>/scripts/reply-pr-comment.sh <comment_id_or_url> [body]
```

- `<comment_id_or_url>`: a `discussion_r<ID>` URL, a full review-comment URL, or the bare numeric comment id.
- `body`: reply text. Omit or pass `-` to read from stdin (recommended for multi-line / quoting).

The script validates the comment exists, replies to the thread root with `gh api -F in_reply_to=<id>` (typed), and prints the new comment URL.

### Manual form (if you cannot use the script)

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments \
  -F in_reply_to=<comment_id>   # MUST be -F (typed int), never -f (string -> 422)
  -f body="Addressed in <sha>: <one-line summary>"
```

`-f` sends strings -> GitHub 422: `in_reply_to is not a number` / `in_reply_to is not a permitted key`. Always `-F` for `in_reply_to`.

## Request a re-review from a bot

`gh pr edit --request-reviewer <bot>` / `POST .../requested_reviewers` **silently ignores bots** (returns 200 with `requested_reviewers: []`). Bots are triggered by a mention comment, not the reviewers API.

1. Find the bot's re-review trigger. For Token Factory / hubert-style bots it is in the bot's **verdict/summary comment footer** (e.g. "To re-review, mention @hubert-code-surgeon"). Fetch it:
   ```bash
   gh api repos/<o>/<r>/issues/<n>/comments --jq '.[] | select(.user.login|test("[bot]$")) | .body' | tail -40
   ```
2. Post a top-level PR comment mentioning the bot. Use the `@<name>[bot]` form (GitHub's mentionable form for bot accounts; it contains `@<name>` as a substring so substring-matchers also fire):
   ```bash
   gh pr comment <n> --body "@<bot-name>[bot] re-review please - pushed \`<sha>\`: <one-line summary>"
   ```
   If the bot auto-reviews on `synchronize` (push), the push may already trigger it — but an explicit mention is reliable.

## Parse a comment URL the user pastes

- `.../pull/<n>#discussion_r<id>` -> inline **review-thread** comment; `<id>` is the `in_reply_to` value.
- `.../pull/<n>#issuecomment-<id>` -> top-level **issue** comment; there is no thread, so "replying" means posting a new issue comment (`gh pr comment`).
- A reply within a thread still has its own `discussion_r<id>`; `in_reply_to` should target the **root** comment id (the helper script resolves this automatically).

Fetch a comment's full body by id:
```bash
gh api repos/<o>/<r>/pulls/<n>/comments --jq '.[] | select(.id == <id>) | {user: .user.login, path, line, body}'
```

## Error visibility — never swallow failures

When a `gh api` call returns **no output**, the real error is on **stderr**. Re-run **without** `2>/dev/null` (and without `--jq` swallowing) to see it:

```bash
gh api -X POST repos/<o>/<r>/pulls/<n>/comments -F in_reply_to=<id> -f body="..." 2>&1 | head -20
```

Don't assume "(no output)" means success — verify by re-listing the thread:
```bash
gh api repos/<o>/<r>/pulls/<n>/comments --jq '.[] | select(.in_reply_to_id == <id>) | {id, html_url}'
```

## Guardrails

- Reply in-thread only to **review-thread** comments. For general issue comments there is no thread — post a new issue comment.
- Never push to trunk. Don't submit draft reviews unless the user asks.
- If `gh` auth fails, surface it — don't work around it.
- Quote the fix commit short hash + one-line summary in the reply body so reviewers can jump to the diff. Build the commit URL locally (see REFERENCE.md).

See [REFERENCE.md](REFERENCE.md) for the full API mechanics, the draft-pending-review flow, and troubleshooting (422s, "Extra data", bot triggers).
