# Theming

This repo uses **TokyoNight Moon** as the primary theme across all tools. Gruvbox Dark and Catppuccin Mocha are available as alternates but currently disabled.

## Architecture

There is no single "switch" that changes every tool at once. Each tool has its own theme config that must be changed independently. The one exception is tmux, which has a shared theme engine (see below).

## Per-Tool Configuration

### Terminal Emulators

**Kitty** (`.config/kitty/kitty.conf`):
- Theme is set via `include` at the bottom of `kitty.conf`
- Three theme files available, swap the active `include` line:
  - `theme-tokyonight-moon.conf` (active)
  - `theme-gruvbox-dark.conf`
  - `theme-catppuccin.conf`

**Ghostty** (`.config/ghostty/config`):
- Theme is set via `config-file = theme-gruvbox-dark`
- Only Gruvbox Dark is currently configured for Ghostty

### Neovim (`.config/nvim/lua/plugins/theme.lua`)

Two colorscheme plugins are configured; toggle via `enabled = true/false`:
- `folke/tokyonight.nvim` — active, using the `tokyonight-moon` style
- `sainnhe/gruvbox-material` — disabled

Lualine (`.config/nvim/lua/plugins/statusline.lua`) uses `theme = "auto"`, so it automatically inherits whatever colorscheme is active.

### Tmux (`.config/tmux/`)

Tmux has the most structured theme system in this repo:

1. **`themes/`** — shell scripts that define `THEME_*` color variables (e.g. `THEME_BG`, `THEME_ACCENT`, `THEME_FG`). Each file also defines an optional `theme_extras()` function for theme-specific overrides.
   - `tokyonight-moon.sh` (active)
   - `gruvbox.sh`

2. **`scripts/apply-theme.sh`** — a shared layout engine. It sources a theme file, then applies all the color variables to tmux options (status bar, pane borders, window formats, prefix highlight, etc.).

3. **`tmux.conf`** — selects the theme by calling:
   ```
   run-shell "~/.config/tmux/scripts/apply-theme.sh ~/.config/tmux/themes/tokyonight-moon.sh"
   ```
   To switch themes, swap which `run-shell` line is uncommented.

There is also a legacy `plugin_config/theme-catppuccin.conf` for the catppuccin tmux plugin, but it is not sourced.

### Shell / CLI Tools

**FZF** (`.zshrc`):
- `FZF_DEFAULT_OPTS` sets `--color=gutter:#222436` (TokyoNight Moon background)
- The tmux session picker (`.config/tmux/plugin_config/sessions.conf`) also passes `--color "gutter:#222436,border:#ff966c,label:#ff966c"` to fzf-tmux

**bat** (syntax highlighter):
- `BAT_THEME=tokyonight-moon` is exported in `.zshrc`
- The theme file lives at `.config/bat/themes/tokyonight-moon.tmTheme` (TextMate format)

**delta** (git diff viewer):
- Configured in `.gitconfig` via `[include] path = ~/.config/delta/themes/<theme>.gitconfig`
- Two theme files available in `.config/delta/themes/`:
  - `tokyonight-moon.gitconfig`
  - `claude-code.gitconfig` (active — a custom variant that also uses the `tokyonight-moon` bat syntax theme)

**btop** (`.config/btop/btop.conf`):
- `color_theme = "tokyo-night"`
- Theme file: `.config/btop/themes/tokyo-night.theme`

**yazi** (`.config/yazi/theme.toml`):
- `dark = "tokyo-night"`
- Flavor files in `.config/yazi/flavors/tokyo-night.yazi/`

**Starship** prompt (`.config/starship.toml`):
- Uses `#ff966c` (TokyoNight Moon's orange) for the prompt box-drawing characters

**gh-dash** (`.config/gh-dash/config.yml`):
- Has a `theme:` section but uses defaults (no custom colors set)

### Neovide (`.config/nvim/lua/config/neovide.lua`)

- Sets the GUI theme to `"dark"`

## How to Switch Themes

To change the theme across all tools, update each of these independently:

| Tool       | What to change                                                          |
|------------|-------------------------------------------------------------------------|
| Kitty      | Swap the `include` line in `kitty.conf`                                 |
| Ghostty    | Change `config-file` in `config`                                        |
| Neovim     | Toggle `enabled` flags in `theme.lua`                                   |
| Tmux       | Swap the `run-shell` line in `tmux.conf`                                |
| bat        | Change `BAT_THEME` in `.zshrc`                                          |
| delta      | Change `[include] path` in `.gitconfig`                                 |
| FZF        | Update `--color` in `FZF_DEFAULT_OPTS` in `.zshrc`                      |
| btop       | Change `color_theme` in `btop.conf`                                     |
| yazi       | Change `dark` flavor in `theme.toml`                                    |
| Starship   | Update hex colors in `starship.toml`                                    |

## Available Themes

| Theme              | Kitty | Ghostty | Neovim | Tmux | bat | delta | btop | yazi |
|--------------------|-------|---------|--------|------|-----|-------|------|------|
| TokyoNight Moon    | yes   | —       | yes    | yes  | yes | yes   | yes  | yes  |
| Gruvbox Dark       | yes   | yes     | yes    | yes  | —   | —     | —    | —    |
| Catppuccin Mocha   | yes   | —       | —      | —    | —   | —     | —    | —    |
