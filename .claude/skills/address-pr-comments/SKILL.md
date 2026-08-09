---
name: address-pr-comments
description: Triage comments on the current pull request, decide which are worth addressing, and commit one fix per comment with the comment text and permalink in the commit message. Optionally leave draft replies in a pending GitHub review for manual submission. Use when the user asks to address PR comments, review PR feedback, go through pull request comments, fix review comments, or triage review threads.
---

# Address PR Comments

Read every comment on the PR for the current branch, triage what is worth fixing, and commit **one fix per comment**. Each commit message quotes the comment and links to it. Optionally queue draft replies in a pending review so the user can submit them from the GitHub UI.

## Quick start

1. Fetch and summarize comments (resolve `scripts/fetch-pr-comments.sh` against this skill's directory):
   ```bash
   bash <skill-dir>/scripts/fetch-pr-comments.sh [PR_NUMBER]
   ```
   Prints a markdown triage report to stdout and writes full JSON (with GraphQL node ids needed for replies) to a temp path printed on the final `JSON:` line. With no argument it uses the PR for the current branch.
2. Present the triage to the user and ask which comments to address (see Triage).
3. For each chosen comment: make the change, stage only the relevant files, commit with the message format below.
4. If the user wants draft replies, follow Leave draft replies (optional).

## Triage

Read the report and classify each comment as one of:

- **address** - actionable code/config change you can make confidently now.
- **skip** - already resolved, outdated, a nitpick not worth a commit, or out of scope.
- **needs-discussion** - ambiguous or risky; do not commit. Surface it to the user.

Present a compact table (comment id, author, location, verdict, one-line reason) and **wait for the user to confirm which to address** before committing. Default to skipping resolved/outdated threads unless the user asks otherwise.

## Address: one commit per comment

For each comment the user confirms:

1. Make the smallest change that addresses it.
2. `git add` only the files that change belongs to this comment - do not bundle multiple comments into one commit.
3. Commit with a conventional summary plus a comment block. Write the message to a file and use `git commit -F <file>` (or a heredoc) so quoting is reliable:

   ```
   <type>: <short summary of the change>

   Addresses PR review comment by <author>:

   > <comment body, trimmed to the meaningful part; collapse long bodies with …>

   PR: <pr html_url>
   Comment: <comment html_url>
   ```

   - `<type>`: `fix`, `refactor`, `style`, `docs`, `test`, `chore`, etc.
   - For a general (issue) comment or a review summary rather than an inline thread, replace "PR review comment" with "PR comment" or "PR review".
   - Always include both `PR:` and `Comment:` lines with the real permalinks from the report.

4. After all commits, show `git log --oneline -<n>` and the list of commits. Do not push unless the user asks.

## Leave draft replies (optional)

Only when the user asks, and only for **inline review-thread comments** (general issue comments cannot be drafted - replying to them posts immediately). Queue replies into a single **pending** review the user will review and submit from the PR UI:

1. Create one pending review (omit `event` to keep it draft) and capture `id` + `node_id`:
   ```bash
   gh api --method POST repos/<owner>/<repo>/pulls/<n>/reviews \
     --input - <<<'{"body":"Replies to review comments (draft)"}'
   ```
2. For each reply, build the commit's GitHub URL locally so the reply links to the fix even before it is pushed:
   ```bash
   owner_repo=$(gh repo view --json owner,name -q '.owner.login + "/" + .name')
   full_sha=$(git rev-parse <commit_short_hash>)
   commit_url="https://github.com/${owner_repo}/commit/${full_sha}"
   ```
   The URL is well-formed from the local SHA; it will 404 on github.com until the commit is pushed, but include it anyway so reviewers can jump to the diff once it lands.
3. Use the GraphQL `addPullRequestReviewComment` mutation with the pending review's `node_id` and the **root comment's** `node_id` (from the JSON the fetch script wrote), and put the commit URL in the reply body:
   ```bash
   gh api graphql -f query='
   mutation($r: ID!, $p: ID!, $b: String!) {
     addPullRequestReviewComment(input: {pullRequestReviewId: $r, inReplyTo: $p, body: $b}) {
      comment { id }
     }
   }' -F r=<review_node_id> -F p=<root_comment_node_id> \
     -F b="Fixed in <commit short hash>: <one-line summary>
${commit_url}"
   ```
4. Tell the user the pending review URL and that they can edit/submit it from the PR's "Files changed" view. Do **not** submit it for them.

See [REFERENCE.md](REFERENCE.md) for the verified API mechanics, comment types, and troubleshooting.

## Guardrails

- One commit per addressed comment. Never combine fixes for multiple comments.
- Stage only the files relevant to the current comment.
- Never push to trunk. Do not push at all unless the user asks; default is local commits.
- If `gh` auth fails, surface it - do not work around it.
- If the current branch has no PR, stop and tell the user.
- Re-run the fetch script after committing if you need refreshed thread state.
