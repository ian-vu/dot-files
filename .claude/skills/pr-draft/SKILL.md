---
name: pr-draft
description: Draft a pull request description from the current branch's commits and diff against trunk, using the repo's PR template. Confirms whether a PR already exists and offers to open one in draft mode if not. Use when the user asks to write a PR description, draft a PR, open a PR, or prepare a branch for review.
---

# PR Draft Skill

Draft a PR description grounded in the actual branch changes and the repo's PR template, then either update the existing PR or open a new draft.

## Workflow

Run steps 1–4 in parallel where possible — they're read-only.

### 1. Identify trunk and branch state

- Trunk name: `git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | sed 's|^origin/||'` (fallback: try `main`, then `master`).
- Current branch: `git branch --show-current`.
- If current branch == trunk, stop and tell the user — there's nothing to PR.

### 2. Collect changes vs trunk

Compare against **local trunk** (`<trunk>`), not `origin/<trunk>`. The local ref reflects what the branch was actually cut from and avoids noise when origin has unrelated upstream commits the user hasn't pulled. If local trunk is missing, fall back to `origin/<trunk>`.

- Commits: `git log --no-merges --pretty=format:'%h %s' <trunk>..HEAD`
- Diffstat: `git diff --stat <trunk>...HEAD`
- Full diff (only if needed for understanding): `git diff <trunk>...HEAD`
- Note any uncommitted/unpushed work: `git status` and `git log @{u}..HEAD` (if upstream exists).

Use `...` (three dots) so the diff is from the merge-base, isolating "what this branch adds" even if trunk has moved on.

### 3. Locate the PR template

Check in this order, use the first that exists:

- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE/*.md` (multiple templates — ask user which)
- `docs/pull_request_template.md`
- `pull_request_template.md` at repo root

If none exists, fall back to a minimal structure: **Summary** + **Test plan**.

### 4. Check whether a PR already exists

`gh pr view --json number,url,state,isDraft,title,body 2>/dev/null`

Branch this on the result:

- **PR exists** → show the user: number, URL, state, title. Ask whether to (a) update its description, (b) just draft text for them to paste, or (c) leave it alone.
- **No PR** → continue to step 5.

### 5. Draft the description

Fill in the template using only what's evident from commits + diff. For each template section:

- **Summary / What**: 1–3 bullets focused on *why* the change exists, not a commit-by-commit replay.
- **Test plan**: extract from test files touched in the diff; if no tests changed, list the manual checks the user should run.
- **Screenshots / Other**: leave a `<!-- TODO -->` placeholder rather than inventing content.

Do not invent ticket numbers, reviewers, or context not present in the branch. If a section needs info you don't have, mark it `<!-- TODO: ... -->` and call it out when presenting the draft.

### 6. Confirm with the user

Show the drafted description and ask:

- Does this look right?
- Any sections to expand, trim, or fix?
- **If no PR exists**: "Open as a draft PR now?" (default: draft, not ready-for-review).
- **If PR exists**: "Update the existing PR description?"

Wait for confirmation before any `gh` write action.

### 7. Create or update the PR

- Push the branch first if it has no upstream: `git push -u origin <branch>`.
- Create draft: `gh pr create --draft --title "<title>" --body "$(cat <<'EOF' ... EOF)"` — pass body via heredoc to preserve formatting.
- Update existing: `gh pr edit <num> --body "$(cat <<'EOF' ... EOF)"`.
- Title default: first commit subject, or branch name humanised. Confirm with the user if it's noisy.

After success, print the PR URL on its own line so it's easy to click.

## Guardrails

- Never run `gh pr create` or `gh pr edit` without explicit user confirmation in this turn.
- Never push to trunk. Never mark an existing draft as ready-for-review unless the user asks.
- If `gh` isn't authenticated (`gh auth status` fails), surface that to the user instead of trying to work around it.
- Keep the title under 70 chars; details belong in the body.
