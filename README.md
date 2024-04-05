# My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

### Brew packages/applications

This will install the required `gnu-stow` brew along with
all formulas and applications

```bash
brew bundle install -v
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```bash
git clone git@github.com:ian-vu/dot-files.git ~/dot-files
cd dot-files
```

then use GNU stow to create symlinks

```bash
stow .
```

### Manual commands needed to complete setup

#### Tmux

1. Clone TPM (Tmux Plugin Manager) into

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

2. Install plugins from tmux

```
<prefix> + I
```

```
<Ctr+Space> + <S-i>
```

#### Neovim

**Ruby environment**
For the ruby LSP to work, the `Mason` dependency of `solargraph` is required.
For this to successfully be install a version of ruby > 2.7 is required.

Using `asdf`:

```bash
asdf plugin add ruby
asdf install ruby 3.3.0
asdf global ruby 3.3.0
```

## Useful information

### Brewfile

#### Adding new formula

Add a new row with one of the following

```bash
brew <formula_name>
tap <tap_name>
cask <cask_name>
```

Then run the following commands

```bash
brew bundle cleanup -v
brew bundle install -v
```

## More information

See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
