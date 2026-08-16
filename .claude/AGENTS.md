# Agent Instructions

## Vendored Skills

Some skills in this directory are vendored from upstream repositories instead of authored directly in this dotfiles repo.

Vendored sources are listed in the repo-only manifest:

```text
.claude/skills/.vendored-skills.tsv
```

Refresh vendored skills with:

```sh
cd ~/dot-files && just update-vendored-skills
```

The updater downloads each configured upstream raw file and overwrites the corresponding local skill file. Treat files listed in the manifest as generated/vendor-owned: do not make local edits there unless you also intend to maintain them as a fork or update the manifest workflow.

If you need custom behavior, prefer creating a separate local skill rather than editing a vendored skill directly.
