---
name: discuss
description: Enter read-only discussion mode to reason about possible code, config, or documentation changes before editing. Use when the user says "discuss", "talk through", "no code changes", "plan first", or asks what changes the agent thinks it should make.
---

# Discuss

## Core rule

Do not change files, run formatters, apply patches, commit, install packages, or perform any other mutating action while this skill is active.

## Allowed actions

- Ask clarifying questions when requirements are ambiguous.
- Read files and inspect repository state.
- Run read-only commands such as `ls`, `find`, `rg`, `git status`, `git diff`, or test commands only if they do not modify files.
- Explain what changes you would make and why.
- Compare options, risks, tradeoffs, and likely implementation steps.

## Workflow

1. Restate the goal and confirm this is discussion-only.
2. Inspect relevant files if needed, using read-only operations.
3. Present proposed changes as a plan, not as edits.
4. Call out uncertainties, risks, and questions.
5. If implementation is requested, explicitly confirm leaving discuss mode before making changes.

## Output format

Prefer concise sections:

- `Understanding` — what the user wants.
- `Proposed changes` — what you would edit, grouped by file or concern.
- `Why` — rationale and tradeoffs.
- `Questions` — anything needed before implementation.

## Boundaries

If the user asks for code snippets, provide illustrative snippets only and state that they are not applied. If a command might generate, cache, rewrite, install, or delete anything, do not run it in discuss mode.
