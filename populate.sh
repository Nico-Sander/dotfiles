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

# --- Stow dotfiles first ---
# Do this first so that the config files exist in ~ before trying to install plugins for them.
echo -e "${BLUE}[>] Stowing config files...${NC}"
stow --target="$HOME" --ignore=populate.sh .
echo -e "    ${GREEN}[+] Dotfiles linked successfully.${NC}"

# 2. Check, Install, and Set Zsh as Default
echo -e "${BLUE}[*] Checking for Zsh...${NC}"
if ! command -v zsh &> /dev/null; then
    echo -e "    [>] Zsh not found. Installing..."
    sudo apt update
    sudo apt install -y zsh
else
    echo -e "    ${GREEN}[+] Zsh is already installed.${NC}"
fi

# Change the default shell if it isn't currently Zsh
CURRENT_SHELL=$(getent passwd "$USER" | awk -F: '{print $7}')
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    # Pause and prompt the user
    read -p "$(echo -e "    ${YELLOW}[?] Do you want to set Zsh as your default shell? [y/N]: ${NC}")" -n 1 -r
    echo "" # Print a clean newline after their input

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

# 2. Check and Install tmux
echo -e "${BLUE}[*] Checking for tmux...${NC}"
if ! command -v tmux &> /dev/null; then
    echo -e "    [>] tmux not found. Installing..."
    # Using sudo means the script will pause here and ask for your password on a fresh machine
    sudo apt update
    sudo apt install -y tmux
else
    echo -e "    ${GREEN}[+] tmux is already installed.${NC}"
fi

# 3. Check and Install TPM (Tmux Plugin Manager)
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
echo -e "${BLUE}[*] Checking for Tmux Plugin Manager (TPM)...${NC}"
if [ ! -d "$TPM_DIR" ]; then
    echo -e "    [>] TPM not found. Cloning from GitHub..."
    # Ensure the parent directory exists just in case
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo -e "    ${GREEN}[+] TPM is already installed.${NC}"
fi

# 4. Headless Plugin Installation
echo -e "${BLUE}[>] Installing tmux plugins headlessly...${NC}"
# Start the tmux server in the background so TPM can talk to it
tmux start-server

# Create a detached dummy session so we have an active environment
tmux new-session -d -s bootstrap_session

# Source your newly stowed config file
tmux source-file "$HOME/.config/tmux/tmux.conf"

# Run the TPM headless install script
# This reads your tmux.conf and downloads vim-tmux-navigator and any other plugins
"$TPM_DIR/bin/install_plugins"

# Clean up by killing the dummy session
tmux kill-session -t bootstrap_session

echo -e "    ${GREEN}[+] Plugins installed successfully.${NC}"

# 5. Check, Install, and Sync Kanata
echo -e "${BLUE}[*] Checking for Kanata...${NC}"
if ! command -v kanata &> /dev/null; then
    echo -e "    [>] Kanata not found. Running full installation..."
    echo -e "    ${YELLOW}[!] This script requires elevated privileges to set up users and systemd.${NC}"
    
    # We use 'bash' here just in case the executable bit (+x) got lost in Git
    sudo bash "$HOME/.config/kanata/install_ubuntu.sh"
else
    echo -e "    ${GREEN}[+] Kanata is already installed.${NC}"
    echo -e "    [>] Syncing kanata.kbd config to system directory..."
    
    # Copy the symlinked config from the home directory to the system directory
    sudo cp "$HOME/.config/kanata/kanata.kbd" /etc/kanata/kanata-config.kbd
    
    # Restart the service to apply the new keymaps
    sudo systemctl restart kanata.service
    
    echo -e "    ${GREEN}[+] Kanata service restarted with the latest config.${NC}"
fi

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN} [+] Setup Complete! Your system is ready.${NC}"
echo -e "${GREEN}==========================================${NC}"
