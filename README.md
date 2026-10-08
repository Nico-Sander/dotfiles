# Dotfiles

This repo contains the configuration files for my programs used in Linux distributions (Ubuntu 26.04).

## Usage

- Clone this repo to your local machine
- Run the populate script: `./populate.sh`
- Undo everything it installed and linked: `./unpopulate.sh`

## Layout

Every top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/) package that mirrors `$HOME`:

| Package   | Links to                     |
|-----------|------------------------------|
| `zsh`     | `~/.zshrc`, `~/.p10k.zsh`    |
| `nvim`    | `~/.config/nvim/`            |
| `tmux`    | `~/.config/tmux/`            |
| `wezterm` | `~/.config/wezterm/`         |
| `kanata`  | `~/.config/kanata/`          |
| `code`    | `~/.config/Code/User/`       |

`scripts/` holds helper scripts that are not linked anywhere.

To add a new config, e.g. for `foo` at `~/.config/foo/foo.conf`, create
`foo/.config/foo/foo.conf` and add `foo` to `STOW_PACKAGES` in both `populate.sh` and `unpopulate.sh`.

Packages are stowed with `--no-folding`, so only files are symlinked and directories like
`~/.config/tmux/` stay real directories. Programs writing runtime data next to their config never write into this repo.

## The populate script

- Installs the apt packages (zsh, tmux, fzf, ripgrep, lsd, bat, zoxide, wl-clipboard, ...)
- Links all packages into `$HOME`
- Clones the zsh plugins into `~/.local/share/zsh/plugins` (update them with `zsh-plugins-update`)
- Installs the latest stable Neovim to `~/.local/opt/nvim`, linked to `~/.local/bin/nvim`
  (update with `./populate.sh --update-nvim`)
- Installs WezTerm and Kanata
