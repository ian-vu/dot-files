# My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

### Git

```
brew install git
```

### Stow

```
brew install stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```
git clone git@github.com:ian-vu/dot-files.git
cd dotfiles
```

then use GNU stow to create symlinks

```
stow .

## More information
See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
```
