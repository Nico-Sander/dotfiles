#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define color codes for professional output formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} [*] Bootstrapping Environment Setup${NC}"
echo -e "${BLUE}==========================================${NC}"

# ===========================================================================
# Prerequisites
# ===========================================================================
echo -e "${BLUE}[>] Installing system prerequisites...${NC}"
sudo apt update -q
sudo apt install -y \
    stow \
    curl \
    build-essential \
    libfuse2 \
    xclip \
    lsd \
    bat \
    zoxide \
    unzip \
    fontconfig
echo -e "    ${GREEN}[+] Prerequisites installed.${NC}"

# ===========================================================================
# Stow dotfiles
# ===========================================================================
echo -e "${BLUE}[>] Stowing config files...${NC}"
stow --target="$HOME" --ignore=populate.sh .
echo -e "    ${GREEN}[+] Dotfiles linked successfully.${NC}"

# ===========================================================================
# Zsh
# ===========================================================================
echo -e "${BLUE}[*] Checking for Zsh...${NC}"
if ! command -v zsh &> /dev/null; then
    echo -e "    [>] Zsh not found. Installing..."
    sudo apt install -y zsh
else
    echo -e "    ${GREEN}[+] Zsh is already installed.${NC}"
fi

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
# fzf (from source for the latest version)
# ===========================================================================
echo -e "${BLUE}[*] Checking for fzf...${NC}"
if [ ! -d "$HOME/.fzf" ]; then
    echo -e "    [>] fzf not found. Installing from source..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all
    echo -e "    ${GREEN}[+] fzf installed.${NC}"
else
    echo -e "    ${GREEN}[+] fzf is already installed.${NC}"
fi

# ===========================================================================
# nvm + Node.js LTS
# ===========================================================================
echo -e "${BLUE}[*] Checking for nvm...${NC}"
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "    [>] nvm not found. Installing..."
    NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
    export NVM_DIR="$HOME/.nvm"
    \. "$NVM_DIR/nvm.sh"
    echo -e "    [>] Installing Node.js LTS..."
    nvm install --lts
    echo -e "    ${GREEN}[+] nvm ${NVM_LATEST} + Node.js LTS installed.${NC}"
else
    echo -e "    ${GREEN}[+] nvm is already installed.${NC}"
fi

# ===========================================================================
# Neovim AppImage (pinned to v0.12.3)
# ===========================================================================
NVIM_VERSION="v0.12.3"
NVIM_DIR="/opt/nvim"
echo -e "${BLUE}[*] Checking for Neovim ${NVIM_VERSION}...${NC}"
if [ ! -f "$NVIM_DIR/nvim" ]; then
    echo -e "    [>] Neovim not found. Installing AppImage to ${NVIM_DIR}..."
    sudo mkdir -p "$NVIM_DIR"
    sudo curl -Lo "$NVIM_DIR/nvim" \
        "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.appimage"
    sudo chmod +x "$NVIM_DIR/nvim"
    echo -e "    ${GREEN}[+] Neovim ${NVIM_VERSION} installed.${NC}"
else
    echo -e "    ${GREEN}[+] Neovim is already installed at ${NVIM_DIR}/nvim.${NC}"
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
# JetBrainsMono Nerd Font
# ===========================================================================
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
echo -e "${BLUE}[*] Checking for JetBrainsMonoNL Nerd Font...${NC}"
if [ ! -d "$FONT_DIR" ]; then
    echo -e "    [>] Font not found. Downloading from Nerd Fonts..."
    mkdir -p "$FONT_DIR"
    curl -Lo /tmp/JetBrainsMono.zip \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
    rm /tmp/JetBrainsMono.zip
    fc-cache -f "$FONT_DIR"
    echo -e "    ${GREEN}[+] JetBrainsMonoNL Nerd Font installed.${NC}"
else
    echo -e "    ${GREEN}[+] JetBrainsMonoNL Nerd Font is already installed.${NC}"
fi

# ===========================================================================
# tmux
# ===========================================================================
echo -e "${BLUE}[*] Checking for tmux...${NC}"
if ! command -v tmux &> /dev/null; then
    echo -e "    [>] tmux not found. Installing..."
    sudo apt install -y tmux
else
    echo -e "    ${GREEN}[+] tmux is already installed.${NC}"
fi

# ===========================================================================
# Clipboard utilities
# ===========================================================================
# tmux-yank and Neovim's "unnamedplus" both shell out to these; without them
# yanking silently does nothing.
echo -e "${BLUE}[*] Checking for clipboard utilities...${NC}"
for pkg in xclip wl-clipboard; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo -e "    [>] $pkg not found. Installing..."
        sudo apt update
        sudo apt install -y "$pkg"
    else
        echo -e "    ${GREEN}[+] $pkg is already installed.${NC}"
    fi
done

# ===========================================================================
# TPM + plugins (headless install)
# ===========================================================================
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
echo -e "${BLUE}[*] Checking for Tmux Plugin Manager (TPM)...${NC}"
if [ ! -d "$TPM_DIR" ]; then
    echo -e "    [>] TPM not found. Cloning from GitHub..."
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo -e "    ${GREEN}[+] TPM is already installed.${NC}"
fi

echo -e "${BLUE}[>] Installing tmux plugins headlessly...${NC}"
tmux start-server
tmux new-session -d -s bootstrap_session
tmux source-file "$HOME/.config/tmux/tmux.conf"
"$TPM_DIR/bin/install_plugins"
tmux kill-session -t bootstrap_session
echo -e "    ${GREEN}[+] Plugins installed successfully.${NC}"

# ===========================================================================
# Kanata
# ===========================================================================
echo -e "${BLUE}[*] Checking for Kanata...${NC}"
if ! command -v kanata &> /dev/null; then
    echo -e "    [>] Kanata not found. Running full installation..."
    echo -e "    ${YELLOW}[!] This script requires elevated privileges to set up users and systemd.${NC}"
    sudo bash "$HOME/.config/kanata/install_ubuntu.sh"
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
