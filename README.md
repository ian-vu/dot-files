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

## More information

See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
