#!/bin/bash

# Usage: ./populate.sh [--update-nvim]
#   --update-nvim   replace the installed Neovim with the latest stable release

# Exit immediately if a command exits with a non-zero status
set -e

# Define color codes for professional output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# stow resolves packages relative to the current directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Stow packages: each top-level directory mirrors $HOME
STOW_PACKAGES=(zsh nvim tmux wezterm kanata code)

UPDATE_NVIM=false
[[ "$1" == "--update-nvim" ]] && UPDATE_NVIM=true

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} [*] Bootstrapping Environment Setup${NC}"
echo -e "${BLUE}==========================================${NC}"

# ===========================================================================
# apt packages
# ===========================================================================
# build-essential + tree-sitter-cli: nvim-treesitter compiles its parsers
# wl-clipboard: clipboard for tmux and Neovim ("unnamedplus") on Wayland
echo -e "${BLUE}[>] Installing apt packages...${NC}"
sudo apt update -q
sudo apt install -y \
    stow \
    curl \
    build-essential \
    zsh \
    tmux \
    fzf \
    ripgrep \
    lsd \
    bat \
    zoxide \
    wl-clipboard
# tree-sitter-cli recommends nodejs + node-gyp (~70 packages), which are only
# needed to generate parsers from grammar.js. nvim-treesitter generates from
# grammar.json with the native runtime, so skip the recommends.
sudo apt install -y --no-install-recommends tree-sitter-cli
echo -e "    ${GREEN}[+] apt packages installed.${NC}"

# ===========================================================================
# Stow dotfiles
# ===========================================================================
# --no-folding links individual files instead of whole directories, so
# programs writing into e.g. ~/.config/tmux never write into this repo.
echo -e "${BLUE}[>] Stowing config files...${NC}"
stow --no-folding --target="$HOME" "${STOW_PACKAGES[@]}"
echo -e "    ${GREEN}[+] Dotfiles linked successfully.${NC}"

# ===========================================================================
# Zsh plugins (plain git clones, sourced directly by .zshrc)
# ===========================================================================
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
ZSH_PLUGINS=(
    romkatv/powerlevel10k
    zsh-users/zsh-syntax-highlighting
    zsh-users/zsh-autosuggestions
    zsh-users/zsh-completions
    Aloxaf/fzf-tab
)
echo -e "${BLUE}[*] Checking for zsh plugins...${NC}"
mkdir -p "$ZSH_PLUGIN_DIR"
for repo in "${ZSH_PLUGINS[@]}"; do
    name="${repo#*/}"
    if [ -d "$ZSH_PLUGIN_DIR/$name" ]; then
        echo -e "    ${GREEN}[+] ${name} is already installed.${NC}"
    else
        echo -e "    [>] Cloning ${repo}..."
        git clone --quiet --depth=1 "https://github.com/${repo}.git" "$ZSH_PLUGIN_DIR/$name"
    fi
done
echo -e "    ${GREEN}[+] Zsh plugins ready (update with: zsh-plugins-update).${NC}"

# ===========================================================================
# Default shell
# ===========================================================================
CURRENT_SHELL=$(getent passwd "$USER" | awk -F: '{print $7}')
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    read -p "$(echo -e "    ${YELLOW}[?] Do you want to set Zsh as your default shell? [y/N]: ${NC}")" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "    [>] Changing default shell to Zsh..."
        chsh -s "$ZSH_PATH"
        echo -e "    ${YELLOW}[!] Note: You will need to log out and log back in for the shell change to take full effect.${NC}"
    else
        echo -e "    ${YELLOW}[>] Skipping default shell change. Keeping $CURRENT_SHELL as the default.${NC}"
    fi
else
    echo -e "    ${GREEN}[+] Zsh is already the default shell.${NC}"
fi

# ===========================================================================
# Neovim (latest stable release tarball, in userspace)
# ===========================================================================
# Unpacked to ~/.local/opt/nvim and linked into ~/.local/bin. No sudo needed;
# update with: ./populate.sh --update-nvim
NVIM_DIR="$HOME/.local/opt/nvim"
NVIM_LINK="$HOME/.local/bin/nvim"

_install_latest_nvim() {
    local arch
    case "$(uname -m)" in
        x86_64|amd64)  arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo -e "    ${RED}[!] Unsupported architecture $(uname -m) for Neovim. Skipping.${NC}"
            return 0
            ;;
    esac

    local tmp
    tmp=$(mktemp -d)
    curl -fLo "$tmp/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    rm -rf "$NVIM_DIR"
    mkdir -p "$(dirname "$NVIM_DIR")" "$(dirname "$NVIM_LINK")"
    mv "$tmp/nvim-linux-${arch}" "$NVIM_DIR"
    rm -rf "$tmp"
    ln -sfn "$NVIM_DIR/bin/nvim" "$NVIM_LINK"
    echo -e "    ${GREEN}[+] $("$NVIM_LINK" --version | head -n1) installed to ${NVIM_DIR}.${NC}"
}

echo -e "${BLUE}[*] Checking for Neovim...${NC}"
if [ ! -x "$NVIM_DIR/bin/nvim" ]; then
    echo -e "    [>] Neovim not found. Installing latest stable release..."
    _install_latest_nvim
elif $UPDATE_NVIM; then
    echo -e "    [>] Updating Neovim to the latest stable release..."
    _install_latest_nvim
else
    echo -e "    ${GREEN}[+] $("$NVIM_DIR/bin/nvim" --version | head -n1) is already installed (update with --update-nvim).${NC}"
fi

# ===========================================================================
# WezTerm (nightly)
# ===========================================================================
echo -e "${BLUE}[*] Checking for WezTerm...${NC}"
if ! command -v wezterm &> /dev/null; then
    echo -e "    [>] WezTerm not found. Installing nightly..."
    curl -fsSL https://apt.fury.io/wez/gpg.key \
        | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt update -q
    sudo apt install -y wezterm-nightly
    echo -e "    ${GREEN}[+] WezTerm nightly installed.${NC}"
else
    echo -e "    ${GREEN}[+] WezTerm is already installed.${NC}"
fi

# ===========================================================================
# GNOME Shell extensions
# ===========================================================================
# Downloaded from extensions.gnome.org for the running shell version.
# Settings live in gnome/extensions.dconf (save changes with
# scripts/dump-gnome-extensions.sh). On Wayland the shell only loads newly
# installed extensions after logging out and back in.
GNOME_EXTENSIONS=(
    blur-my-shell@aunetx
    just-perfection-desktop@just-perfection
    multi-monitors-bar@frederykabryan
    perfect-fit@ryliov.work.com
    focus-changer@heartmire
    focus@scaryrawr.github.io
)
echo -e "${BLUE}[*] Checking for GNOME Shell extensions...${NC}"
if ! command -v gnome-extensions &> /dev/null; then
    echo -e "    ${YELLOW}[!] gnome-extensions not available — skipping (non-GNOME system?).${NC}"
else
    SHELL_VERSION=$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)
    INSTALLED_EXTENSIONS=$(gnome-extensions list)
    for uuid in "${GNOME_EXTENSIONS[@]}"; do
        if grep -qxF "$uuid" <<< "$INSTALLED_EXTENSIONS"; then
            echo -e "    ${GREEN}[+] ${uuid} is already installed.${NC}"
            continue
        fi
        echo -e "    [>] Installing ${uuid}..."
        tmp=$(mktemp -d)
        if curl -fsSLo "$tmp/extension.zip" \
            "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?shell_version=${SHELL_VERSION}"; then
            gnome-extensions install --force "$tmp/extension.zip"
        else
            echo -e "    ${RED}[!] No release of ${uuid} for GNOME ${SHELL_VERSION}. Skipping.${NC}"
        fi
        rm -rf "$tmp"
    done

    # gnome-extensions enable only knows extensions the running shell has
    # loaded, so add them to the enabled list directly
    enabled=$(gsettings get org.gnome.shell enabled-extensions)
    enabled=${enabled#@as }
    for uuid in "${GNOME_EXTENSIONS[@]}"; do
        [[ "$enabled" == *"'${uuid}'"* ]] && continue
        if [[ "$enabled" == "[]" ]]; then
            enabled="['${uuid}']"
        else
            enabled="${enabled%]}, '${uuid}']"
        fi
    done
    gsettings set org.gnome.shell enabled-extensions "$enabled"
    gsettings set org.gnome.shell disable-user-extensions false

    dconf load /org/gnome/shell/extensions/ < "$DOTFILES_DIR/gnome/extensions.dconf"
    echo -e "    ${GREEN}[+] Extensions enabled and settings loaded.${NC}"
    echo -e "    ${YELLOW}[!] Log out and back in to load newly installed extensions.${NC}"
fi

# ===========================================================================
# Tmux keybind conflict check
# ===========================================================================
echo -e "${BLUE}[*] Checking for system keybind conflicts with tmux...${NC}"
_check_tmux_keybind_conflicts() {
    local tmux_conf="$HOME/.config/tmux/tmux.conf"

    if [[ ! -f "$tmux_conf" ]]; then
        echo -e "    ${YELLOW}[!] tmux config not found at $tmux_conf — skipping.${NC}"
        return 0
    fi
    if ! command -v gsettings &>/dev/null; then
        echo -e "    ${YELLOW}[!] gsettings not available — skipping (non-GNOME system?).${NC}"
        return 0
    fi

    local all_settings conflicts=0 raw_key gnome_key matches
    all_settings=$(gsettings list-recursively 2>/dev/null)

    while IFS= read -r line; do
        # Skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue
        # Match no-prefix Alt binds: bind -n M-<key>
        [[ "$line" =~ ^[[:space:]]*bind[[:space:]]+-n[[:space:]]+M-([^[:space:]]+) ]] || continue
        raw_key="${BASH_REMATCH[1]}"

        # Convert to GNOME accelerator format; capital letter implies <Shift>
        if [[ "$raw_key" =~ ^[A-Z]$ ]]; then
            gnome_key="<Alt><Shift>${raw_key,,}"
        else
            gnome_key="<Alt>${raw_key}"
        fi

        # Search all gsettings for this accelerator, ignore empty arrays.
        # grep exits 1 when nothing matches; don't let set -e abort on that.
        matches=$(echo "$all_settings" \
            | grep -F "'${gnome_key}'" \
            | grep -Ev "@as \[\]|'\[\]'") || true

        if [[ -n "$matches" ]]; then
            echo -e "    ${RED}[!] Conflict: tmux M-${raw_key} (${gnome_key}) clashes with:${NC}"
            echo "$matches" | while IFS= read -r m; do
                echo -e "        ${YELLOW}${m}${NC}"
            done
            conflicts=$((conflicts + 1))
        fi
    done < "$tmux_conf"

    if [[ "$conflicts" -eq 0 ]]; then
        echo -e "    ${GREEN}[+] No keybind conflicts found.${NC}"
    else
        echo -e "    ${RED}[!] ${conflicts} conflict(s) found above. Clear them with:${NC}"
        echo -e "    ${YELLOW}    gsettings set <schema> <key> '[]'${NC}"
    fi
}
_check_tmux_keybind_conflicts

# ===========================================================================
# Kanata
# ===========================================================================
echo -e "${BLUE}[*] Checking for Kanata...${NC}"
if ! command -v kanata &> /dev/null; then
    echo -e "    [>] Kanata not found. Running full installation..."
    echo -e "    ${YELLOW}[!] This script requires elevated privileges to set up users and systemd.${NC}"
    sudo bash "$DOTFILES_DIR/scripts/install-kanata.sh"
else
    echo -e "    ${GREEN}[+] Kanata is already installed.${NC}"
    echo -e "    [>] Syncing kanata.kbd config to system directory..."
    sudo cp "$HOME/.config/kanata/kanata.kbd" /etc/kanata/kanata-config.kbd
    sudo systemctl restart kanata.service
    echo -e "    ${GREEN}[+] Kanata service restarted with the latest config.${NC}"
fi

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN} [+] Setup Complete! Your system is ready.${NC}"
echo -e "${GREEN}==========================================${NC}"
