---
name: work-summary
description: Create or update concise, recoverable work summaries for the current coding session in an Obsidian vault, with per-file symlinks back into the repo. Use when the user asks for a session recap, work log, standup update, PR or async status summary, or asks to write a summary into notes or an Obsidian vault.
---

# Work Summary

Create or update a dated work summary in `~/notes/04_Archive/work-summaries/`, then expose it from the repo through `.work-summaries/`.

## Workflow

1. Choose filename keywords: 2-4 lowercase words joined with underscores, enough to identify the topic while scanning file names, such as `auth_refactor` or `spider_debug`.
2. Check for existing summaries for today in `~/notes/04_Archive/work-summaries/`. If a relevant file already exists, read it and merge or append without discarding existing content.
3. Resolve this skill directory from the loaded `SKILL.md` path. Use the scripts in `scripts/`; do not hard-code Claude skill paths.
4. Generate the filename:

   ```bash
   <skill-dir>/scripts/make-filename.sh <keywords> <repo-or-worktree-dir>
   ```

5. Generate frontmatter:

   ```bash
   <skill-dir>/scripts/make-frontmatter.sh <repo-or-worktree-dir>
   ```

6. Read `references/template.md`, combine the generated frontmatter with the summary body, and write the result to `~/notes/04_Archive/work-summaries/<filename>`.
7. Create or refresh the repo symlink:

   ```bash
   <skill-dir>/scripts/setup-symlink.sh <filename> <repo-root>
   ```

## Scripts

- `scripts/get-metadata.sh [directory]` - collect git context as `key=value` pairs.
- `scripts/make-filename.sh <keywords> [directory]` - generate the dated summary filename.
- `scripts/make-frontmatter.sh [directory]` - generate Obsidian frontmatter and links.
- `scripts/setup-symlink.sh <filename> [repo-root]` - create `.work-summaries/`, ignore it locally, and symlink one file.
- `scripts/link-summaries.sh [repo-name] [repo-root]` - recreate all symlinks for a repo.

## Quality Bar

Write enough detail that a future session can reconstruct what changed and why without rereading the conversation. Include specific file paths, commands, queries, decisions, and meaningful outputs. Omit conversational back-and-forth.

