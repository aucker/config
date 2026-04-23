setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
unsetopt AUTO_REMOVE_SLASH
unsetopt HIST_EXPIRE_DUPS_FIRST
unsetopt EXTENDED_HISTORY

set -o emacs

# PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH=$PATH:"/mnt/c/Users/asus/AppData/Local/Programs/Microsoft VS Code/bin/"
export NPM_CONFIG_PREFIX="$HOME/.nvm/versions/node/v22.19.0"
export PATH="/home/asus/.nvm/versions/node/v22.19.0/bin:$PATH"

export PATH=$HOME/toolchains/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04/bin:$PATH

export PATH=/usr/local/cuda-12.8/bin:$PATH

export PATH=$HOME/toolchains/cmake-3.31/bin/:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH

# Rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

# Autoload
autoload -U compinit; compinit
zmodload zsh/complist
autoload -Uz edit-command-line; zle -N edit-command-line

# Plugins
source $ZSHAREDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSHAREDIR/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSHAREDIR/zsh-history-substring-search/zsh-history-substring-search.zsh
fpath=($ZSHAREDIR/zsh-completions/src $fpath)

bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down

[[ $- == *i* ]] && source $ZSHAREDIR/fzf/completion.zsh 2> /dev/null
# source $ZSHAREDIR/fzf/key-bindings.zsh

# Use tmux by default
# if [ "$TERM" = 'xterm-256color' ]; then
#   tmux has -t hack &> /dev/null
#   if [ $? != 0 ]; then
#     tmux new -s hack
#   elif [ -z $TMUX ]; then
#     tmux attach -t hack
#   fi
# fi


# Auto completion
zstyle ":completion:*:*:*:*:*" menu select
zstyle ":completion:*" use-cache yes
zstyle ":completion:*" special-dirs true
zstyle ":completion:*" squeeze-slashes true
zstyle ":completion:*" file-sort change
zstyle ":completion:*" matcher-list "m:{[:lower:][:upper:]}={[:upper:][:lower:]}" "r:|=*" "l:|=* r:|=*"
# source $ZDOTDIR/keymap.zsh

# Tabtab for node cli programs, e.g. `pnpm`
# source $ZDOTDIR/tabtab/pnpm.zsh

# Initialize tools
source $ZDOTDIR/function.zsh
source $ZDOTDIR/fish_compat.zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

alias zed="ZED_ALLOW_EMULATED_GPU=1 WAYLAND_DISPLAY='' zed"
# alias zed="ZED_ALLOW_EMULATED_GPU=1 WAYLAND_DISPLAY=\'\' zed"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Greeting and Tmux auto-start
if [[ -o interactive ]]; then
    zsh_greeting

    # Auto-start tmux only when NOT in Warp terminal and NOT already in tmux
    if [[ "$TERM_PROGRAM" != "WarpTerminal" && -z "$TMUX" ]]; then
        exec tmux
    fi
fi

