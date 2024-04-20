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

#### Symbolic links

Add icloud to a better location

```bash
ln -s ~/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/obsidian ~/obsidian
```

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

**[ChatGPT](https://github.com/jackMort/ChatGPT.nvim)**

This plugin requires an API key to be read on setup.

The cli tool `age` is used to descrypt a file containing the key.

The encrpytion key is required to be found on path `~/.age/secret-key.txt`.

Currently the key is stored in 1Password. To set up the age encryption key run
the following command.

```bash
op read "op://kt76oi5s3tqjg54lvlolplvvaq/Age CLI Identity/password" > ~/.age/secret-key.txt
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

### [age file encryption](https://github.com/FiloSottile/age)

Age is used to encrypt and decrypt files. Encrypted files are suffixed with `.age`.

#### To encrypt a file:

```bash
cat <PATH_TO_FILE> | age --encrypt --identity ~/.age/secret-key.txt > <ENCRYPTED_FILE_PATH>
```

or

```bash
age --encrypt --identity ~/.age/secret-key.txt <PATH_TO_FILE> <ENCRYPTED_FILE_PATH>
```

#### To decrypt a file:

```bash
age --decrypt --identity ~/.age/secret-key.txt <ENCRYPTED_FILE_PATH>
```

## More information

See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
