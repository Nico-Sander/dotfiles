# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PATH (typeset -U drops duplicate entries)
typeset -U path
path=("$HOME/.local/bin" $path "$HOME/.cargo/bin")

# Vi keymap. Set explicitly: otherwise zsh picks vi or emacs at startup
# depending on whether the inherited $EDITOR/$VISUAL contain "vi". Must come
# before the plugins, which bind their keys (Tab, Ctrl+R, ...) in the active
# keymap. Key bindings: see "Keybindings" below.
bindkey -v

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

# Complete hidden files/dirs without typing the leading dot (cd tmux/<Tab>
# -> .config). Unlike `setopt globdots`, this only affects completion, so
# globs like `rm *` still skip dotfiles.
_comp_options+=(globdots)

# Fzf-Tab: after compinit, before plugins that wrap widgets (autosuggestions,
# syntax highlighting)
_zsh_plugin fzf-tab/fzf-tab.plugin.zsh

# Autosuggestions
_zsh_plugin zsh-autosuggestions/zsh-autosuggestions.zsh

# Powerlevel10k Prompt
_zsh_plugin powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==========================
# Keybindings (vi mode)
# ==========================
# Esc switches to normal mode after 10ms instead of 400ms (zsh waits to see
# whether Esc starts a longer sequence like Alt+x or an arrow key).
KEYTIMEOUT=1

# Insert mode keeps a few emacs keys. vi's own Backspace/Ctrl+W/Ctrl+U stop
# at the point where insert mode was entered; these don't.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^[.' insert-last-word

# Accept the grey autosuggestion (→ / End work too)
bindkey -M viins '^Y' autosuggest-accept

# Up/Down: step through history entries that start with what's typed so far
# Ctrl+Left/Right: jump by word
# Ctrl+X Ctrl+E: edit the command line in $EDITOR
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line
for _km in viins vicmd; do
  # Arrows send ESC[A or ESC O A depending on the terminal's cursor key mode
  bindkey -M $_km '^[[A' up-line-or-beginning-search
  bindkey -M $_km '^[OA' up-line-or-beginning-search
  bindkey -M $_km '^[[B' down-line-or-beginning-search
  bindkey -M $_km '^[OB' down-line-or-beginning-search
  bindkey -M $_km '^[[1;5D' backward-word
  bindkey -M $_km '^[[1;5C' forward-word
  bindkey -M $_km '^X^E' edit-command-line
done
unset _km

# Cursor shape: beam in insert mode, block in normal mode and while a command
# runs. add-zle-hook-widget chains with the hooks p10k/autosuggestions use.
_vi_cursor() {
  if [[ $KEYMAP == vicmd ]]; then print -n '\e[2 q'; else print -n '\e[6 q'; fi
}
_vi_cursor_block() { print -n '\e[2 q' }
zle -N _vi_cursor
zle -N _vi_cursor_block
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _vi_cursor
add-zle-hook-widget line-init _vi_cursor
add-zle-hook-widget line-finish _vi_cursor_block

# ==========================
# History
# ==========================
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=$HISTSIZE
setopt share_history         # all shells read/write the history file live
setopt hist_ignore_all_dups  # a repeated command replaces its older copy
setopt hist_ignore_space     # " command" (leading space) is not saved

# Allow `# comments` on the command line (e.g. in pasted snippets)
setopt interactive_comments

# ==========================
# Completion styling
# ==========================
# LS_COLORS (used by the completion list and fzf-tab). Nothing else sets it.
(( $+commands[dircolors] )) && eval "$(dircolors -b)"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --color always $realpath'
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-y:accept'

# ==========================
# Tools & aliases
# ==========================
if (( $+commands[lsd] )); then
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -lA'
  alias lt='lsd --tree --depth 2'
fi

# Bat (Debian/Ubuntu ship the binary as `batcat`). `bat` pages long files,
# `cat` prints everything highlighted, like the real cat.
if (( $+commands[batcat] )); then
  _bat=batcat
  alias bat='batcat'
elif (( $+commands[bat] )); then
  _bat=bat
fi
[[ -n $_bat ]] && alias cat="$_bat --paging=never"

# fzf shell integration: Ctrl+R history, Ctrl+T insert file, Alt+C cd into
# dir, `**<Tab>` fuzzy completion. Ctrl+y accepts everywhere.
if (( $+commands[fzf] )); then
  export FZF_CTRL_R_OPTS="--bind 'ctrl-y:accept'"
  export FZF_CTRL_T_OPTS="--bind 'ctrl-y:accept' --preview 'if [ -d {} ]; then lsd --tree --depth 2 --color always {}; else ${_bat:-cat} --color=always --style=numbers --line-range=:300 {}; fi'"
  export FZF_ALT_C_OPTS="--bind 'ctrl-y:accept' --preview 'lsd --tree --depth 2 --color always {}'"
  source <(fzf --zsh)
fi
unset _bat

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

# Zoxide: `cd` itself becomes zoxide-aware (cd foo jumps to the best match
# for "foo" if it isn't a local dir), `cdi` picks a dir with fzf. Defining
# cd this way (not alias cd=z) keeps completion in the "cd" context.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Syntax Highlighting (must be sourced last)
_zsh_plugin zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
