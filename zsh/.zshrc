# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PATH (typeset -U drops duplicate entries)
typeset -U path
path=("$HOME/.local/bin" $path "$HOME/.cargo/bin")

# ==========================
# Plugins
# ==========================
# Plain git clones, installed by populate.sh. A missing plugin is skipped.
# Update them all with `zsh-plugins-update`.
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

_zsh_plugin() {
  [[ -r "$ZSH_PLUGIN_DIR/$1" ]] && source "$ZSH_PLUGIN_DIR/$1"
}

zsh-plugins-update() {
  local dir
  for dir in "$ZSH_PLUGIN_DIR"/*(/N); do
    print -P "%F{blue}${dir:t}%f"
    git -C "$dir" pull --ff-only --quiet
  done
}

# Extra completion definitions (must be on fpath before compinit)
fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)

# Load completions. Rebuild the dump at most once a day, otherwise reuse it
# without the (slow) security check.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_zcompdump:h}" ]] || mkdir -p "${_zcompdump:h}"
_zcompdump_stale=("$_zcompdump"(N.mh+24))
if (( ${#_zcompdump_stale} )); then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_stale

# Fzf-Tab: after compinit, before plugins that wrap widgets (autosuggestions,
# syntax highlighting)
_zsh_plugin fzf-tab/fzf-tab.plugin.zsh

# Autosuggestions
_zsh_plugin zsh-autosuggestions/zsh-autosuggestions.zsh

# Powerlevel10k Prompt
_zsh_plugin powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Better Vi Mode
# _zsh_plugin zsh-vi-mode/zsh-vi-mode.plugin.zsh

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
(( $+commands[lsd] )) && alias ls='lsd'

# fzf shell integration (completion + key bindings).
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# Bat (Debian/Ubuntu ship the binary as `batcat`)
if (( $+commands[batcat] )); then
  alias bat='batcat'
  alias cat='batcat'
elif (( $+commands[bat] )); then
  alias cat='bat'
fi

# Git (a curated subset of oh-my-zsh's git plugin aliases)
alias g='git'
alias gst='git status'
alias gss='git status --short'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gc='git commit --verbose'
alias 'gc!'='git commit --verbose --amend'
alias gcmsg='git commit --message'
alias gd='git diff'
alias gds='git diff --staged'
alias gsw='git switch'
alias gswc='git switch --create'
alias gco='git checkout'
alias gb='git branch'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias glog='git log --oneline --decorate --graph'
alias grs='git restore'
alias grb='git rebase'
alias gsta='git stash push'
alias gstp='git stash pop'

# Obsidian vault
export VAULT="$HOME/workspace/github.com/Nico-Sander/nico-vault/"
alias notes="cd $VAULT && nvim"

export VISUAL="nvim"
export EDITOR="$VISUAL"

# Conda (only if installed). Sourcing conda.sh defines the `conda` function
# without running Python at startup and without activating base. The prompt
# shows the active env (p10k anaconda segment), so conda must not edit PS1.
for _conda_root in "$HOME/miniforge3" "$HOME/miniconda3" "$HOME/anaconda3"; do
  if [[ -r "$_conda_root/etc/profile.d/conda.sh" ]]; then
    export CONDA_CHANGEPS1=false
    source "$_conda_root/etc/profile.d/conda.sh"
    break
  fi
done
unset _conda_root

# Zoxide
export _ZO_DOCTOR=0
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

# Syntax Highlighting (must be sourced last)
_zsh_plugin zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
