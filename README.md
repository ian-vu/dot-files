# My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

### Brew packages/applications

This will install the required `gnu-stow` brew along with
all formulas and applications

```bash
cd mac
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

### Manual steps needed to complete setup

#### MacOS

Install deps and set up MacOs

```bash
cd mac
./setup.sh
```

### Debian installation

````bash
cd debian
./setup.sh
#### Symbolic links

Add icloud to a better location

```bash
ln -s ~/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/obsidian ~/obsidian
````

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

#### Font

**Maple Mono Nerd Font**

Download release and install by double clicking the font file.

[link](https://github.com/subframe7537/maple-font/releases)

## Useful information

### Brewfile

#### Adding new formula

Add a new row with one of the following lines to the brewfile

```bash
brew <formula_name>
tap <tap_name>
cask <cask_name>
```

Then run the following commands

```bash
cd mac
brew bundle cleanup -v
brew bundle install --cleanup -v
```

_Note:_ to avoid upgrades use `--no-upgrade` flag

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

## Git Configuration

This repository uses a conditional Git configuration setup to automatically switch between personal and work identities based on the directory structure.

### How it works

- **Default (Personal)**: All repositories default to personal email (`personal@gmail.com`)
- **Work Override**: Repositories in `~/dev/work/**` automatically use work email (`work@company.com`)

### Directory Structure

```
~/dev/
├── work/                 # All work repositories go here
│   ├── company-project/ # Current company repositories
│   ├── company-api/
│   └── company-docs/
├── personal/            # Personal repositories
└── [other]/            # Any other repositories (use personal config)
```

### Configuration Files

- **`.gitconfig`** - Main config with personal email as default + conditional include
- **`~/.gitconfig-work`** - Work-specific overrides (email, name, SSH keys, etc.)

### Setup for New Work Environment

When switching companies or setting up on a new work laptop:

1. **Move work repositories**: Place all work repos under `~/dev/work/`
2. **Update work config**: Edit `~/.gitconfig-work` with new work email/settings
3. **No changes needed**: The main `.gitconfig` remains unchanged

### Example Work Config (`~/.gitconfig-work`)

```ini
[user]
    name = Your Name
    email = work@company.com
[core]
    sshCommand = ssh -i ~/.ssh/work_key
```

### Verification

Test the setup in any repository:

```bash
# In work repo
cd ~/dev/work/some-project
git config user.email  # Should show work email

# In personal repo
cd ~/dev/personal/some-project
git config user.email  # Should show personal email
```

## More information

See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
