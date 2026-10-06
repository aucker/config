setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
unsetopt AUTO_REMOVE_SLASH
unsetopt HIST_EXPIRE_DUPS_FIRST
unsetopt EXTENDED_HISTORY

set -o emacs
bindkey '^U' backward-kill-line

# PATH (shared, unique)
typeset -U path PATH
path=($HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin $path)
export GOPROXY=https://goproxy.io,direct

# PATH (platform-specific)
case "$OSTYPE" in
  linux*)
    export PATH=$PATH:"/mnt/c/Users/asus/AppData/Local/Programs/Microsoft VS Code/bin/"
    export PATH=$HOME/toolchains/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04/bin:$PATH
    export PATH=/usr/local/cuda/bin:$PATH
    export PATH=$HOME/toolchains/cmake-3.31/bin/:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    ;;
  darwin*)
    export PATH=$HOME/.composer/vendor/bin:$PATH
    export PATH=$PNPM_HOME:$PATH
    export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
    ;;
esac

# Rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

# Claude w/ DeepSeek
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max

typeset __anthropic_token
if (( $+commands[security] )); then
    __anthropic_token="$(security find-generic-password -a "$USER" -s codex-deepseek-anthropic-token -w 2>/dev/null)"
fi
if [[ -z "$__anthropic_token" && -d "$HOME/config/.git" ]]; then
    __anthropic_token="$(git -C "$HOME/config" config --local --get codexSecrets.anthropicAuthToken 2>/dev/null)"
fi
if [[ -n "$__anthropic_token" ]]; then
    export ANTHROPIC_AUTH_TOKEN="$__anthropic_token"
fi
unset __anthropic_token

# Autoload
fpath=($ZSHAREDIR/zsh-completions/src $fpath)
autoload -U compinit
compinit
zmodload zsh/complist
if [[ -t 0 ]]; then
    autoload -Uz edit-command-line
    zle -N edit-command-line
fi

# Plugins
[[ -r $ZSHAREDIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source $ZSHAREDIR/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r $ZSHAREDIR/zsh-history-substring-search/zsh-history-substring-search.zsh ]] && \
    source $ZSHAREDIR/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

# Auto completion
zstyle ":completion:*:*:*:*:*" menu select
zstyle ":completion:*" use-cache yes
zstyle ":completion:*" special-dirs true
zstyle ":completion:*" squeeze-slashes true
zstyle ":completion:*" file-sort change
zstyle ":completion:*" matcher-list "m:{[:lower:][:upper:]}={[:upper:][:lower:]}" "r:|=*" "l:|=* r:|=*"

# Initialize tools
[[ -r $ZDOTDIR/function.zsh ]] && source $ZDOTDIR/function.zsh
[[ -r $ZDOTDIR/fish_compat.zsh ]] && source $ZDOTDIR/fish_compat.zsh
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# Set up fzf key bindings and fuzzy completion
if [[ -t 0 ]] && (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

alias zed="ZED_ALLOW_EMULATED_GPU=1 WAYLAND_DISPLAY='' zed"

# zsh-syntax-highlighting must be sourced after widget-producing plugins.
[[ -r $ZSHAREDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source $ZSHAREDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Greeting and Tmux auto-start
if [[ -o interactive && -t 0 && -t 1 ]]; then
    [[ "$OSTYPE" == linux* ]] && zsh_greeting

    if [[ -z "$TMUX" && -z "$SSH_CONNECTION" ]] && (( $+commands[tmux] )); then
        typeset tmux_session
        case "$TERM" in
            xterm-kitty)   tmux_session="kit" ;;
            xterm-ghostty) tmux_session="ghost" ;;
        esac

        if [[ -n "$tmux_session" ]]; then
            if tmux has-session -t "$tmux_session" 2>/dev/null; then
                exec tmux attach-session -t "$tmux_session"
            else
                exec tmux new-session -s "$tmux_session"
            fi
        fi
    fi
fi
