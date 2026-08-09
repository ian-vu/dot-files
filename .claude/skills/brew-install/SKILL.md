---
name: brew-install
description: Adds shared Homebrew formulae, casks, and taps to this dotfiles repo's tracked Brewfile and installs them without upgrading unrelated packages. Use when the user asks to install a brew, add a Homebrew package, add a cask, add a tap, or update .homebrew/Brewfile.
---

# Brew Install

## Goal

Add shared Homebrew installations to `.homebrew/Brewfile` and install only missing items. This skill is for tracked, cross-machine packages; do not edit `.homebrew/Brewfile.local` unless the user explicitly leaves this skill's shared-only workflow.

## Repo model

- Shared packages live in `.homebrew/Brewfile`.
- Machine-specific packages live in `.homebrew/Brewfile.local` and are git-ignored; do not use it for this skill.
- Root `just` exposes the Homebrew module as `brew`, so use `just brew ...` commands.
- `.homebrew/.justfile` merges `Brewfile` and `Brewfile.local` into `/tmp/Brewfile.merged` before running Homebrew Bundle.
- `just brew install` runs `brew bundle --file=/tmp/Brewfile.merged install --no-upgrade`, so it installs missing entries without upgrading unrelated packages.

## Workflow

1. Confirm the requested package is meant to be shared across machines. If it sounds private, work-only, licensed, or host-specific, ask before proceeding.
2. Identify the correct Homebrew Bundle entry:
   - Formula/CLI: `brew "name"`
   - GUI app or macOS app bundle: `cask "name"`
   - Third-party source: add `tap "owner/repo"` in the Taps section, then use the tapped formula/cask name if required.
3. Inspect `.homebrew/Brewfile` before editing:
   - Avoid duplicate package entries, even if an existing entry lacks a comment.
   - Keep taps in `# Taps`, formulae in `# Brews`, and apps in `# Casks`.
4. Add a concise comment immediately before each new package explaining what it is or why it is needed.
5. Install without upgrading unrelated packages:

   ```bash
   HOMEBREW_NO_AUTO_UPDATE=1 just brew install
   ```

6. If installation fails because a name is wrong or a tap is missing, fix `.homebrew/Brewfile` and rerun the same install command. Do not run upgrade commands to solve install failures.

## Commands

- Install missing Brewfile entries only: `HOMEBREW_NO_AUTO_UPDATE=1 just brew install`
- Preview cleanup only: `just brew cleanup`
- Do not run unless explicitly requested: `just brew upgrade`, `brew upgrade`, `brew bundle upgrade`, `just brew cleanup-force`

## Editing examples

Formula:

```ruby
# Fast Rust NPM package manager
brew "pnpm"
```

Cask:

```ruby
# GPU-based terminal emulator
cask "kitty"
```

Tap plus tapped formula:

```ruby
# For actionable macOS notifications from AI agent tmux hooks.
tap "vjeantet/tap"

# Actionable macOS alerts used by Pi tmux notifications to jump back on click.
brew "vjeantet/tap/alerter"
```

## Final response

Report the package entry added, whether `just brew install` succeeded, and any follow-up needed. Mention if installation was skipped because the user requested no machine mutation or Homebrew was unavailable.
