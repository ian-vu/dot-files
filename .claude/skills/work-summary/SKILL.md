---
name: work-summary
description: Summarize work done in the current session into a concise status update suitable for standups, PRs, or async comms. Writes to the Obsidian vault with per-file symlinks back to the repo.
---

# Work Summary Skill

Create or update a dated work summary in `~/notes/04_Archive/work-summaries/`, with a per-file symlink in the repo's `.work-summaries/`.

## Scripts

All in this skill directory (`~/.claude/skills/work-summary/`):

| Script                          | Purpose                                                                    |
| ------------------------------- | -------------------------------------------------------------------------- |
| `get-metadata.sh`               | Collect git context as `key=value` pairs (repo, branch, slugs, date, time) |
| `make-filename.sh <keywords>`   | Generate filename from keywords + metadata                                 |
| `make-frontmatter.sh`           | Generate Obsidian frontmatter + `_links:` section                          |
| `setup-symlink.sh <filename>`   | Create `.work-summaries/`, gitignore it, symlink the file                  |
| `link-summaries.sh [repo-name]` | Bulk-recreate all symlinks for a repo                                      |

## Process

1. **Choose keywords** — short sentence for the filename topic - enough to quickly skim and understand what thfile to be about (e.g. `auth_refactor`, `spider_debug`)
2. **Check for existing** — `ls ~/notes/04_Archive/work-summaries/$(date +%Y-%m-%d)@*.md 2>/dev/null`
3. **Generate filename** — `~/.claude/skills/work-summary/make-filename.sh <keywords>`
4. **Generate frontmatter** — `~/.claude/skills/work-summary/make-frontmatter.sh`
5. **Write content** — combine frontmatter output + body (see [TEMPLATE.md](./TEMPLATE.md)) → `~/notes/04_Archive/work-summaries/<filename>`
6. **Create symlink** — `~/.claude/skills/work-summary/setup-symlink.sh <filename>`

If updating an existing file: read it first, append or merge new sections, preserve existing content.

## Quality Bar

A good summary lets someone (or a future Claude session) reconstruct exactly what was done and why, without re-reading the conversation. Include enough detail that specific queries, file paths, and decisions are recoverable.
