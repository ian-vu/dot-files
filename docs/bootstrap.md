# Bootstrap

## Installation

```bash
git clone git@github.com:ian-vu/dot-files.git ~/dot-files
cd ~/dot-files
stow .
```

### macOS

```bash
cd mac
./setup.sh
```

### Debian

```bash
cd debian
./setup.sh
```

## Post-Install Setup

### Tmux

1. Clone TPM (Tmux Plugin Manager):

   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Install plugins from within tmux: `<prefix> + I` (`<Ctrl+Space> + <Shift+I>`)

### Font

Install [Maple Mono Nerd Font](https://github.com/subframe7536/maple-font/releases) — download the release and install by double clicking the font file.

### Neovim

The config is based on kickstart.nvim. See [`.config/nvim/README.md`](../.config/nvim/README.md) for upstream docs.

**Ruby LSP**: The `solargraph` Mason dependency requires Ruby > 2.7:

```bash
asdf plugin add ruby
asdf install ruby 3.3.0
asdf global ruby 3.3.0
```

**[ChatGPT plugin](https://github.com/jackMort/ChatGPT.nvim)**: Requires the [age encryption key](encryption.md) to be set up.

### Symbolic Links

```bash
ln -s ~/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/obsidian ~/notes
```

### Homebrew

See [`.homebrew/README.md`](../.homebrew/README.md) for package management setup and usage.
