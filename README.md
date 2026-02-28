# My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

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
ln -s ~/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/obsidian ~/notes
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

#### Git Blame

After cloning, configure git blame to ignore whitespace-only commits:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

## Useful information

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

Git is configured to automatically switch between personal and work identities based on the directory a repo is cloned into. SSH keys are also selected automatically via `core.sshCommand`.

### Directory Structure

```
~/dev/
├── heidi/              # Work repositories (uses ~/.gitconfig-heidi)
├── personal/           # Personal repositories (uses default config)
└── <workplace>/        # Future workplaces get their own directory + config
```

### How it works

- **Default (Personal)**: `.gitconfig` sets personal identity and `sshCommand` using `~/.ssh/id_ed25519_personal`
- **Work Override**: `includeIf` directives in `.gitconfig` load a workplace-specific config (e.g. `.gitconfig-heidi`) which overrides identity and `sshCommand`

### Adding a new workplace

1. Create the directory: `mkdir ~/dev/<workplace>`
2. Create `.gitconfig-<workplace>` in the dotfiles repo with the workplace identity and SSH key:
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
4. Run `stow .` from the dotfiles repo to symlink the new config file

### Verification

```bash
cd ~/dev/heidi/some-project
git config user.email  # Should show work email

cd ~/dev/personal/some-project
git config user.email  # Should show personal email
```

## More information

See this video on how `stow` works: https://www.youtube.com/watch?v=y6XCebnB9gs
