---
name: pr-draft
description: Create a PR for the current branch, using GitHub's generated PR template body and the branch diff. Starts as draft to read the template reliably, then opens for review by default unless explicitly told not to. Use when the user asks to create, open, draft, or prepare a PR.
---

# PR Creation Skill

Create or update a PR using the same comparison reviewers see on GitHub. For new PRs, create a draft first so GitHub generates the template body, read it back, fill it from branch changes and relevant decisions from this AI session, then mark ready for review by default.

## Workflow

1. **Check state**
   - Base: `git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null | sed 's|^origin/||'` (fallback `main`, then `master`).
   - Branch: `git branch --show-current`; stop if branch == base.
   - Auth: `gh auth status`.
   - Refresh base: `git fetch origin <base>`.

2. **Collect GitHub-equivalent changes**
   - Use `origin/<base>...HEAD` so diffs start at the merge-base, matching GitHub PR review.
   - Commands:
     - `git merge-base origin/<base> HEAD`
     - `git log --no-merges --pretty=format:'%h %s' origin/<base>..HEAD`
     - `git diff --stat origin/<base>...HEAD`
     - `git diff origin/<base>...HEAD` only if needed
     - `git status` and `git log @{u}..HEAD` if upstream exists; call out unpushed/uncommitted work.

3. **Handle existing PR**
   - Run: `gh pr view --json number,url,state,isDraft,title,body 2>/dev/null`.
   - If one exists, update its body from the current branch changes and mark it ready if it is a draft. Do not ask which state to use or request confirmation.

4. **Create draft PR if none exists**
   - Push if needed: `git push -u origin <branch>`.
   - Create as draft first: `gh pr create --draft --title "<title>"`.
   - Do not pass a body/template unless GitHub cannot generate one; the point is to let GitHub create the initial PR body from its configured template.
   - Title should be under 70 chars.

5. **Fill body**
   - Read stored body: `gh pr view <num> --json body -q .body`.
   - Fill template from commits/diff only:
     - Summary: 1–3 bullets focused on why/what.
     - Test plan: tests changed or manual checks to run.
     - Screenshots/unknowns: leave `<!-- TODO -->`.
   - If relevant, include decisions/alternatives from this AI context. If no matching section exists, add `## Design notes`. Do not invent context, ticket numbers, reviewers, or rationale.

6. **Update and open for review**
   - Show the filled body, then run `gh pr edit <num> --body-file <file-or-process-substitution>` without requesting confirmation.
   - Unless the user explicitly asked to keep it draft, run `gh pr ready <num>` after updating the body.
   - Print PR URL alone at the end.

## Guardrails

- Default: create as draft only to reliably capture GitHub's generated template, then open for review by the end.
- Keep draft only when explicitly requested.
- Run `gh pr create`, `gh pr edit`, and `gh pr ready` without requesting confirmation when the user invokes this skill.
- Never push to trunk.
- Surface `gh` auth failures instead of working around them.
