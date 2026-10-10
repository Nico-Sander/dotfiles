#!/bin/bash

# Undo everything populate.sh installed or created.
# Keeps going on individual failures so a partial install can still be cleaned.

# Define color codes for professional output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# stow resolves packages relative to the current directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

# Keep in sync with populate.sh
STOW_PACKAGES=(zsh nvim tmux wezterm kanata code)

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} [*] Tearing Down Environment Setup${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}[!] This removes all packages, files, users and services set up by populate.sh.${NC}"
read -p "$(echo -e "${YELLOW}[?] Continue? [y/N]: ${NC}")" -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[>] Aborted. Nothing was changed.${NC}"
    exit 0
fi

# Ask for sudo up front so later steps don't prompt mid-way
sudo -v || exit 1

# ===========================================================================
# Kanata
# ===========================================================================
echo -e "${BLUE}[*] Removing Kanata...${NC}"
if systemctl list-unit-files kanata.service &> /dev/null; then
    sudo systemctl disable --now kanata.service 2> /dev/null
fi
sudo rm -f /etc/systemd/system/kanata.service
sudo systemctl daemon-reload
sudo systemctl reset-failed kanata.service 2> /dev/null
sudo rm -f /usr/local/bin/kanata
sudo rm -rf /etc/kanata
if [ -f /etc/udev/rules.d/50-kanata.rules ]; then
    sudo rm -f /etc/udev/rules.d/50-kanata.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
fi
if getent passwd kanata &> /dev/null; then
    sudo userdel kanata
fi
for grp in kanata uinput; do
    if getent group "$grp" &> /dev/null; then
        sudo groupdel "$grp"
    fi
done
echo -e "    ${GREEN}[+] Kanata service, binary, config, udev rule, user and groups removed.${NC}"

# ===========================================================================
# GNOME Shell extensions
# ===========================================================================
# Keep in sync with populate.sh
GNOME_EXTENSIONS=(
    blur-my-shell@aunetx
    just-perfection-desktop@just-perfection
    multi-monitors-bar@frederykabryan
    perfect-fit@ryliov.work.com
    focus-changer@heartmire
    focus@scaryrawr.github.io
)
echo -e "${BLUE}[*] Removing GNOME Shell extensions...${NC}"
if command -v gnome-extensions &> /dev/null; then
    for uuid in "${GNOME_EXTENSIONS[@]}"; do
        gnome-extensions disable "$uuid" 2> /dev/null
        gnome-extensions uninstall "$uuid" 2> /dev/null
    done
    # Reset every dconf directory that populate.sh loaded settings into
    grep -oE '^\[[^]/]+' "$DOTFILES_DIR/gnome/extensions.dconf" | tr -d '[' | sort -u \
        | while IFS= read -r dir; do
            dconf reset -f "/org/gnome/shell/extensions/${dir}/"
        done
    echo -e "    ${GREEN}[+] Extensions uninstalled and their settings reset.${NC}"
else
    echo -e "    ${YELLOW}[!] gnome-extensions not available — skipping.${NC}"
fi

# ===========================================================================
# WezTerm apt repository
# ===========================================================================
echo -e "${BLUE}[*] Removing WezTerm apt repository...${NC}"
sudo rm -f /etc/apt/sources.list.d/wezterm.list /usr/share/keyrings/wezterm-fury.gpg
echo -e "    ${GREEN}[+] Repository and signing key removed (package is purged below).${NC}"

# ===========================================================================
# Neovim
# ===========================================================================
echo -e "${BLUE}[*] Removing Neovim...${NC}"
NVIM_DIR="$HOME/.local/opt/nvim"
NVIM_LINK="$HOME/.local/bin/nvim"
if [ -L "$NVIM_LINK" ] && [[ "$(readlink "$NVIM_LINK")" == "$NVIM_DIR/"* ]]; then
    rm -f "$NVIM_LINK"
fi
rm -rf "$NVIM_DIR"
rmdir --ignore-fail-on-non-empty "$HOME/.local/opt" 2> /dev/null
echo -e "    ${GREEN}[+] ${NVIM_DIR} removed.${NC}"

# ===========================================================================
# Zsh plugins
# ===========================================================================
echo -e "${BLUE}[*] Removing zsh plugins...${NC}"
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
rm -rf "$ZSH_PLUGIN_DIR"
rmdir --ignore-fail-on-non-empty "$(dirname "$ZSH_PLUGIN_DIR")" 2> /dev/null
echo -e "    ${GREEN}[+] ${ZSH_PLUGIN_DIR} removed.${NC}"

# ===========================================================================
# Default shell
# ===========================================================================
# Must happen before zsh is purged, otherwise the login shell no longer exists.
echo -e "${BLUE}[*] Checking default shell...${NC}"
CURRENT_SHELL=$(getent passwd "$USER" | awk -F: '{print $7}')
if [[ "$(basename "$CURRENT_SHELL")" == "zsh" ]]; then
    echo -e "    [>] Changing default shell back to /bin/bash..."
    sudo chsh -s /bin/bash "$USER"
    echo -e "    ${YELLOW}[!] Log out and back in for the shell change to take full effect.${NC}"
else
    echo -e "    ${GREEN}[+] Default shell is $CURRENT_SHELL, nothing to change.${NC}"
fi

# ===========================================================================
# Unstow dotfiles
# ===========================================================================
echo -e "${BLUE}[>] Removing dotfile symlinks...${NC}"
if command -v stow &> /dev/null; then
    stow -D --target="$HOME" "${STOW_PACKAGES[@]}"
    # --no-folding created real directories for the links; drop the ones
    # that are now empty (deepest first)
    for pkg in "${STOW_PACKAGES[@]}"; do
        (cd "$pkg" && find . -mindepth 1 -type d | sort -r) | while IFS= read -r dir; do
            rmdir --ignore-fail-on-non-empty "$HOME/${dir#./}" 2> /dev/null
        done
    done
    echo -e "    ${GREEN}[+] Dotfiles unlinked.${NC}"
else
    echo -e "    ${RED}[!] stow not found — cannot unlink dotfiles. Skipping.${NC}"
fi

# ===========================================================================
# Runtime data generated by the dotfiles
# ===========================================================================
# Not written by populate.sh itself, but created on first use of the configs
# it linked (completion cache, p10k cache, lazy.nvim plugins, zoxide database...).
echo -e "${BLUE}[*] Runtime data created by the linked configs:${NC}"
RUNTIME_PATHS=(
    "$HOME/.cache/zsh"
    "$HOME/.cache/p10k-"*
    "$HOME/.cache/gitstatus"
    "$HOME/.local/share/nvim"
    "$HOME/.local/state/nvim"
    "$HOME/.cache/nvim"
    "$HOME/.local/share/zoxide"
)
EXISTING_RUNTIME_PATHS=()
for p in "${RUNTIME_PATHS[@]}"; do
    [ -e "$p" ] && EXISTING_RUNTIME_PATHS+=("$p")
done
if [ ${#EXISTING_RUNTIME_PATHS[@]} -eq 0 ]; then
    echo -e "    ${GREEN}[+] None found.${NC}"
else
    printf '        %s\n' "${EXISTING_RUNTIME_PATHS[@]}"
    read -p "$(echo -e "    ${YELLOW}[?] Delete these too? [y/N]: ${NC}")" -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "${EXISTING_RUNTIME_PATHS[@]}"
        echo -e "    ${GREEN}[+] Runtime data removed.${NC}"
    else
        echo -e "    ${YELLOW}[>] Keeping runtime data.${NC}"
    fi
fi

# ===========================================================================
# apt packages
# ===========================================================================
# Purge everything populate.sh installed, but skip any package whose removal
# would drag along packages outside this list — those were clearly
# pre-existing and something else on the system depends on them.
PACKAGES=(
    stow curl build-essential tree-sitter-cli
    zsh tmux fzf ripgrep lsd bat zoxide wl-clipboard
    wezterm-nightly
)

_is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2> /dev/null | grep -q 'ok installed'
}

echo -e "${BLUE}[*] Purging apt packages...${NC}"
INSTALLED=()
for pkg in "${PACKAGES[@]}"; do
    _is_installed "$pkg" && INSTALLED+=("$pkg")
done

TO_PURGE=()
for pkg in "${INSTALLED[@]}"; do
    collateral=$(apt-get -s purge "$pkg" 2> /dev/null \
        | awk '/^(Purg|Remv) /{print $2}' \
        | sed 's/:.*//' \
        | grep -vxF -f <(printf '%s\n' "${INSTALLED[@]}"))
    if [[ -n "$collateral" ]]; then
        echo -e "    ${YELLOW}[!] Keeping $pkg — removing it would also remove: $(echo $collateral)${NC}"
    else
        TO_PURGE+=("$pkg")
    fi
done

if [ ${#TO_PURGE[@]} -gt 0 ]; then
    echo -e "    [>] Purging: ${TO_PURGE[*]}"
    sudo apt-get purge -y "${TO_PURGE[@]}"
    sudo apt-get autoremove --purge -y
    echo -e "    ${GREEN}[+] Packages purged.${NC}"
else
    echo -e "    ${GREEN}[+] No packages to purge.${NC}"
fi

# Drop the removed WezTerm repo from the package index
sudo apt-get update -q

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN} [+] Teardown Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "${YELLOW}[!] Reboot (or log out and back in) so the shell and udev changes fully apply.${NC}"
