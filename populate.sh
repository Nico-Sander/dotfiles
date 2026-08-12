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
    unzip \
    fontconfig
echo -e "    ${GREEN}[+] Prerequisites installed.${NC}"

# ===========================================================================
# Modern CLI tools (lsd, bat, zoxide) via latest GitHub release .deb
# ===========================================================================
# Ubuntu's apt versions are missing or stale: jammy has no "lsd" package at
# all, and ships bat 0.19.0 / zoxide 0.4.3 against current upstream releases
# of 0.26+ / 0.10+. Pull the latest .deb from GitHub instead so dependency
# resolution and uninstall still go through apt/dpkg normally.
_install_latest_github_deb() {
    local bin_name="$1" repo="$2" pattern="$3"

    if command -v "$bin_name" &> /dev/null; then
        echo -e "    ${GREEN}[+] ${bin_name} is already installed.${NC}"
        return 0
    fi

    echo -e "    [>] ${bin_name} not found. Fetching latest release from ${repo}..."
    local url
    url=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"browser_download_url"' \
        | grep -E "$pattern" \
        | head -n1 \
        | cut -d'"' -f4)

    if [[ -z "$url" ]]; then
        echo -e "    ${RED}[!] Could not find a matching .deb release asset for ${bin_name}. Skipping.${NC}"
        return 0
    fi

    local tmp_deb="/tmp/${bin_name}.deb"
    curl -Lo "$tmp_deb" "$url"
    sudo apt install -y "$tmp_deb"
    rm -f "$tmp_deb"
    echo -e "    ${GREEN}[+] ${bin_name} installed ($(basename "$url")).${NC}"
}

echo -e "${BLUE}[*] Checking for lsd, bat, zoxide...${NC}"
_install_latest_github_deb "lsd" "lsd-rs/lsd" '/lsd_[0-9][^"]*_amd64\.deb'
_install_latest_github_deb "bat" "sharkdp/bat" '/bat_[0-9][^"]*_amd64\.deb'
_install_latest_github_deb "zoxide" "ajeetdsouza/zoxide" '/zoxide_[0-9][^"]*_amd64\.deb'

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
# fzf (latest release binary from GitHub)
# ===========================================================================
# Ubuntu ships an old fzf (jammy: 0.29, noble: 0.44) that predates the
# `fzf --zsh` shell-integration flag (added in 0.48). The .zshrc relies on
# `source <(fzf --zsh)`, so anything older prints "unknown option: --zsh"
# during zsh startup. Install the latest prebuilt binary to /usr/local/bin,
# which shadows any apt-provided /usr/bin/fzf, and upgrade if it's too old.
FZF_MIN_VERSION="0.48.0"  # first release with `fzf --zsh`

# True (0) if $1 >= $2, comparing dotted version strings.
_version_ge() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

_install_latest_fzf() {
    local arch
    case "$(uname -m)" in
        x86_64|amd64)  arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo -e "    ${RED}[!] Unsupported architecture $(uname -m) for fzf. Skipping.${NC}"
            return 0
            ;;
    esac

    local tag ver url tmp
    tag=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$tag" ]]; then
        echo -e "    ${RED}[!] Could not determine latest fzf release. Skipping.${NC}"
        return 0
    fi
    ver="${tag#v}"
    url="https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${ver}-linux_${arch}.tar.gz"

    tmp=$(mktemp -d)
    curl -Lo "$tmp/fzf.tar.gz" "$url"
    tar -xzf "$tmp/fzf.tar.gz" -C "$tmp"
    sudo install -m 755 "$tmp/fzf" /usr/local/bin/fzf
    rm -rf "$tmp"
    echo -e "    ${GREEN}[+] fzf ${ver} installed to /usr/local/bin.${NC}"
}

echo -e "${BLUE}[*] Checking for fzf...${NC}"
if command -v fzf &> /dev/null; then
    FZF_CURRENT=$(fzf --version | awk '{print $1}')
else
    FZF_CURRENT=""
fi

if [[ -z "$FZF_CURRENT" ]]; then
    echo -e "    [>] fzf not found. Installing latest release..."
    _install_latest_fzf
elif _version_ge "$FZF_CURRENT" "$FZF_MIN_VERSION"; then
    echo -e "    ${GREEN}[+] fzf ${FZF_CURRENT} is installed and recent enough.${NC}"
else
    echo -e "    ${YELLOW}[>] fzf ${FZF_CURRENT} is outdated (< ${FZF_MIN_VERSION}). Upgrading...${NC}"
    _install_latest_fzf
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

        # Search all gsettings for this accelerator, ignore empty arrays
        matches=$(echo "$all_settings" \
            | grep -F "'${gnome_key}'" \
            | grep -Ev "@as \[\]|'\[\]'")

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
