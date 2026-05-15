# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

. "$HOME/.local/bin/env"
export PATH="$PATH:/opt/nvim/"
export PATH="$PATH:/opt/nvim12/"

# Set the directory to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yer
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)" 
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add Powerlevel10k Prompt
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Syntax Hightlighting
zinit light zsh-users/zsh-syntax-highlighting

# Autocompletions
zinit light zsh-users/zsh-completions

# Autosuggestions
zinit light zsh-users/zsh-autosuggestions

# Add snippets
zinit snippet OMZP::git

# Load completions
autoload -U compinit && compinit

# Fzf-Tab
zinit light Aloxaf/fzf-tab

# Better Vi Mode
# zinit ice depth=1
# zinit light jeffreytse/zsh-vi-mode


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey '^y' autosuggest-accept

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-y:accept'
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:accept'"

# Aliases
alias ls='lsd'

# Shell integrations
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(fzf --zsh)"

# Zoxide
eval "$(zoxide init zsh)"
alias cd='z'

# Bat
alias cat='batcat'

# Obsidian vault
export VAULT="$HOME/workspace/github.com/Nico-Sander/nico-vault/"
alias notes="cd $VAULT && nvim"
