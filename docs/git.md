# Git Configuration

Git automatically switches between personal and work identities based on the directory a repo is cloned into. SSH keys are also selected automatically via `core.sshCommand`.

## Directory Structure

```
~/dev/
├── heidi/              # Work repos (uses ~/.gitconfig-heidi)
├── personal/           # Personal repos (uses default config)
└── <workplace>/        # Future workplaces get their own directory + config
```

## How it works

- **Default (Personal)**: `.gitconfig` sets personal identity and `sshCommand` using `~/.ssh/id_ed25519_personal`
- **Work Override**: `includeIf` directives load a workplace-specific config (e.g. `.gitconfig-heidi`) which overrides identity and `sshCommand`

## Adding a new workplace

1. Create the directory: `mkdir ~/dev/<workplace>`
2. Create `.gitconfig-<workplace>` in the dotfiles repo:
   ```ini
   [user]
       name = Your Name
       email = you@workplace.com
   [core]
       sshCommand = ssh -i ~/.ssh/<workplace_key>
   ```
3. Add an `includeIf` to the **end** of `.gitconfig` (must come after `[core]` to override `sshCommand`):
   ```ini
   [includeIf "gitdir:~/dev/<workplace>/"]
       path = ~/.gitconfig-<workplace>
   ```
4. Run `stow .` to symlink the new config file

## Verification

```bash
cd ~/dev/heidi/some-project
git config user.email  # Should show work email

cd ~/dev/personal/some-project
git config user.email  # Should show personal email
```

## Git Blame

Configure git blame to ignore whitespace-only commits:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```
