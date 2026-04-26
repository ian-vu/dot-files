---
name: work-summary
description: Summarize work done in the current session into a concise status update suitable for standups, PRs, or async comms. Includes repo/branch/worktree metadata if in a git repo.
---

# Work Summary Skill

Create or update a dated work summary file in `.work-summaries/` (relative to the current working directory).

## Metadata

If inside a git repository, collect context to include in the summary header:

```sh
git rev-parse --show-toplevel 2>/dev/null         # repo/worktree root
git rev-parse --abbrev-ref HEAD 2>/dev/null        # branch
git worktree list 2>/dev/null                      # worktree list
```

**Important — worktree-aware repo name:**
`git rev-parse --show-toplevel` inside a linked worktree returns the *worktree* path, not the main repo root. To get the actual repo name:

```sh
# Get the main worktree (first line of git worktree list), then extract its basename
git worktree list | head -1 | awk '{print $1}' | xargs basename
```

This ensures the repo name is always `ml-scribe` (not `OT-and-P-explore` or similar worktree directory name).

- **Worktree**: if `git worktree list` shows more than one entry AND the current directory is not the main worktree, include the current worktree directory name in the header. Otherwise omit.
- If any command fails, skip that field — the summary works without git.

Include a metadata block at the top of the file, after the title. Only include fields that are available:

```markdown
> **Repo:** <repo-name> | **Branch:** <branch> | **Worktree:** <worktree-path>
```

## File Naming

Files use this pattern: `YYYY-MM-DD|<repo>|<context-slug>|<short-keywords>.md`

- Date is today's date (use `date +%Y-%m-%d` if unsure)
- Repo: the git repo name (from `git worktree list | head -1 | awk '{print $1}' | xargs basename` — NOT `git rev-parse --show-toplevel` which returns the worktree path in linked worktrees). Sanitize to lowercase alphanumeric and hyphens. If not in a git repo, omit.
- Context slug (max 20 chars, truncated): the git worktree directory name if in a linked worktree, otherwise the branch name. Sanitize to lowercase alphanumeric and hyphens only (replace `/`, `_`, and other special chars with `-`, collapse consecutive hyphens, strip leading/trailing hyphens). If not in a git repo, omit the context slug.
- Keywords: 2–4 lowercase words joined with underscores, derived from the main topic of the session (e.g. `feed_updates`, `auth_refactor`, `spider_debug`)
- Delimiter between segments is `|` (pipe)
- Check if a file for today already exists with matching context slug and keywords — if so, update it rather than creating a new one

Examples:
- Repo `aladdin`, worktree `aladdin-feat-spider`: `2026-04-24|aladdin|aladdin-feat-spider|spider_debug.md`
- Repo `myapp`, branch `feat/auth-refactor`: `2026-04-24|myapp|feat-auth-refactor|auth_cleanup.md`
- Repo `myapp`, branch `very-long-feature-branch-name-here`: `2026-04-24|myapp|very-long-feature-bra|feed_updates.md`
- Not in a git repo: `2026-04-24|notes_cleanup.md`

To find existing today's summaries:

```bash
ls .work-summaries/$(date +%Y-%m-%d)\|*.md 2>/dev/null
```

## File Format

```markdown
# <Title — concise description of the work> — <YYYY-MM-DD>

## Background

Brief context: why this work was needed, what prompted it.

## Summary

2–5 sentence overview of what was accomplished this session. Should be readable standalone — someone skimming the file should understand the outcome without reading the detail sections.

## 1. <Section heading>

### Finding / Change

Describe what was discovered or done. Include:

- Relevant code paths and line numbers
- SQL queries run (with results if significant)
- Commands executed
- Key decisions made

## 2. <Next section>

...

## Key Takeaways

- Bullet list of important learnings, gotchas, or decisions that should be remembered
- Particularly note: non-obvious behaviour, things that could trip up future work, permanent changes made

## Next Session Checklist

<!-- Only include this section if there are follow-ups, audits, or planned work.
     Omit the section entirely if nothing is pending. -->

### Audit / Verify

- [ ] <thing to check that was changed today — e.g. "Confirm rkt_feed meta update did not re-enable null stores on next run">

### Planned Work

- [ ] <next concrete task — e.g. "Investigate cj_feed meta_update_interval behaviour for edge case X">

### Open Questions

- <unresolved question or unknown that may need investigation>
```

## Process

1. Review the conversation history to extract all meaningful work done this session
2. Determine 2–4 keyword slug for the filename based on the dominant topic
3. Check if a matching file already exists for today
4. If updating: read the existing file, then append or merge new sections — preserve existing content
5. If creating: write a new file with the full format above
6. Be thorough — include SQL queries, code snippets, file paths, and command outputs that were significant
7. Omit conversational back-and-forth; only include substantive findings and actions
8. At the end, consider whether there are any follow-ups, verifications, or planned tasks — if so, populate the **Next Session Checklist** section; otherwise omit it entirely

## Quality Bar

A good summary should let someone (or a future Claude session) reconstruct exactly what was done and why, without needing to re-read the conversation. Include enough detail that specific queries, file paths, and decisions are recoverable.
