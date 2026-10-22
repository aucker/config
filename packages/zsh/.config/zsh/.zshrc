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

# PATH (portable platform defaults)
if [[ "$OSTYPE" == darwin* ]]; then
    path=($HOME/.composer/vendor/bin ${PNPM_HOME:+$PNPM_HOME} $path)
fi

# Per-host paths and environment values belong in this untracked file. Start
# with local.zsh.example, which is installed beside this configuration.
[[ -r "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

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

# Optional per-host mappings contain store references, never secret values.
if [[ -r "$ZDOTDIR/secret-loader.zsh" ]]; then
    source "$ZDOTDIR/secret-loader.zsh"
    [[ -r "$ZDOTDIR/secrets.local.zsh" ]] && source "$ZDOTDIR/secrets.local.zsh"
    # Missing or locked stores are allowed; an inherited token is preserved.
    dotfiles_load_secret ANTHROPIC_AUTH_TOKEN keychain codex-deepseek-anthropic-token || true
fi

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
