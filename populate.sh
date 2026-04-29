#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================="
echo " 🚀 Bootstrapping Environment Setup "
echo "=========================================="

# 1. Stow dotfiles first
# We do this first so that the config files exist in ~ before we try to install plugins for them.
echo "📦 Stowing config files..."
stow --target="$HOME" --ignore=populate.sh .
echo "   ✅ Dotfiles linked successfully."

# 2. Check and Install tmux
echo "🔍 Checking for tmux..."
if ! command -v tmux &> /dev/null; then
    echo "   ⚙️ tmux not found. Installing..."
    # Using sudo means the script will pause here and ask for your password on a fresh machine
    sudo apt update
    sudo apt install -y tmux
else
    echo "   ✅ tmux is already installed."
fi

# 3. Check and Install TPM (Tmux Plugin Manager)
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
echo "🔍 Checking for Tmux Plugin Manager (TPM)..."
if [ ! -d "$TPM_DIR" ]; then
    echo "   ⚙️ TPM not found. Cloning from GitHub..."
    # Ensure the parent directory exists just in case
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "   ✅ TPM is already installed."
fi

# 4. Headless Plugin Installation
echo "🔌 Installing tmux plugins headlessly..."
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

echo "   ✅ Plugins installed successfully."

echo "=========================================="
echo " 🎉 Setup Complete! Your system is ready. "
echo "=========================================="
