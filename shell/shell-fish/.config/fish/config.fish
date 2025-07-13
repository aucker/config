# =============================================================================
# FISH CONFIGURATION
# =============================================================================

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Set Homebrew PATH (must be early in config)
set -gx PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH

# Set Python PATH
set -gx PATH /Users/aucker/Library/Python/3.13/bin $PATH

# Set default editor
set -gx EDITOR nvim

# FZF configuration
set -gx FZF_DEFAULT_COMMAND 'fd --type file --follow'
set -gx FZF_CTRL_T_COMMAND 'fd --type file --follow'
set -gx FZF_DEFAULT_OPTS '--height 20%'

# Colored man output
set -gx LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
set -gx LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
set -gx LESS_TERMCAP_me \e'[0m'           # end mode
set -gx LESS_TERMCAP_se \e'[0m'           # end standout-mode
set -gx LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
set -gx LESS_TERMCAP_ue \e'[0m'           # end underline
set -gx LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline

# =============================================================================
# ABBREVIATIONS
# =============================================================================

# System shortcuts
abbr -a yr 'cal -y'
abbr -a e nvim
abbr -a vi nvim
abbr -a vimdiff 'nvim -d'

# Development shortcuts
abbr -a c cargo
abbr -a ct 'cargo t'
abbr -a m make

# Git shortcuts
abbr -a g git
abbr -a gc 'git checkout'
abbr -a ga 'git add -p'
abbr -a gah 'git stash; and git pull --rebase; and git stash pop'
abbr -a pr 'gh pr create -t (git show -s --format=%s HEAD) -b (git show -s --format=%B HEAD | tail -n+3)'

# AWS shortcuts
abbr -a amz 'env AWS_SECRET_ACCESS_KEY=(pass www/aws-secret-key | head -n1)'
abbr -a ais "aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | {iid: .InstanceId, type: .InstanceType, key:.KeyName, state:.State.Name, host:.PublicDnsName}'"

# Keybase shortcuts
abbr -a ks 'keybase chat send'
abbr -a kr 'keybase chat read'
abbr -a kl 'keybase chat list'

# =============================================================================
# DYNAMIC ABBREVIATIONS (conditional on available tools)
# =============================================================================

# Better ls with eza if available
if command -v eza &>/dev/null
    abbr -a l 'eza'
    abbr -a ls 'eza'
    abbr -a ll 'eza -l'
    abbr -a lll 'eza -la'
else
    abbr -a l 'ls'
    abbr -a ll 'ls -l'
    abbr -a lll 'ls -la'
end

# =============================================================================
# INTERACTIVE SHELL CONFIGURATION
# =============================================================================

#if status --is-interactive
#    # Base16 theme support
#    if test -d ~/dev/others/base16/templates/fish-shell
#        set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
#        builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
#    end
#
#    # Auto-start tmux (except in tmux or linux terminal)
#    switch $TERM
#        case 'linux'
#            # Skip tmux in linux console
#        case '*'
#            if not set -q TMUX
#                exec tmux
#            end
#    end
#end

# =============================================================================
# EXTERNAL TOOL INTEGRATION
# =============================================================================

# Autojump integration
if test -f /usr/share/autojump/autojump.fish
    source /usr/share/autojump/autojump.fish
end

# Zoxide integration (better cd)
if command -v zoxide &>/dev/null
    zoxide init fish | source
end

# =============================================================================
# FISH PROMPT CONFIGURATION
# =============================================================================

# Git prompt settings
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate ''
set __fish_git_prompt_showupstream 'none'
set -g fish_prompt_pwd_dir_length 3

# =============================================================================
# KEY BINDINGS
# =============================================================================

function fzf_history --description "Search command history with fzf"
    history | fzf | read -l line
    and commandline $line
end

bind \cr fzf_history

function fish_user_key_bindings
    bind \cz 'fg>/dev/null ^/dev/null'
    if functions -q fzf_key_bindings
        fzf_key_bindings
    end
end

# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================

# Navigate to git repository root
function d --description "Navigate to git repository root"
    while test $PWD != "/"
        if test -d .git
            break
        end
        cd ..
    end
end

# Executes a command after a countdown
function countdown --description "Run a command after a countdown"
    argparse --name countdown h/help -- $argv
    if set -q _flag_h
        printf "Usage: countdown <seconds> <command...>\n"
        return 0
    end

    if test (count $argv) -lt 2
        printf "Usage: countdown <seconds> <command...>\n" >&2
        return 1
    end

    set -l seconds $argv[1]
    set -l cmd_to_run $argv[2..-1]

    if not string match -r '^[0-9]+$' -- "$seconds"
        echo "Error: <seconds> must be an integer." >&2
        return 1
    end

    tput sc # Save cursor
    for i in (seq $seconds -1 1)
        tput rc # Restore cursor
        tput el # Clear to end of line
        printf "Running '%s' in %ss..." "$cmd_to_run" $i
        sleep 1
    end

    tput rc # Restore cursor
    tput el # Clear to end of line
    eval $cmd_to_run
end

# 1Password CLI helper
function pwl --description "Sign in to 1Password"
    set -Ux OP_SESSION_my (pw signin my --raw)
end

# SSH wrapper for specific hosts
function ssh --description "SSH wrapper with terminal fixes"
    switch $argv[1]
        case "*.amazonaws.com"
            env TERM=xterm /usr/bin/ssh $argv
        case "ubuntu@*"
            env TERM=xterm /usr/bin/ssh $argv
        case "*"
            /usr/bin/ssh $argv
    end
end

# Password manager integrations
function apass --description "Send password to Android device"
    if test (count $argv) -ne 1
        pass $argv
        return
    end
    asend (pass $argv[1] | head -n1)
end

function qrpass --description "Show password as QR code"
    if test (count $argv) -ne 1
        pass $argv
        return
    end
    qrsend (pass $argv[1] | head -n1)
end

function asend --description "Send text to Android device via ADB"
    if test (count $argv) -ne 1
        echo "No argument given"
        return
    end
    adb shell input text (echo $argv[1] | sed -e 's/ /%s/g' -e 's/\([#[()<>{}$|;&*\\~"\'`]\)/\\\\\1/g')
end

function qrsend --description "Display text as QR code"
    if test (count $argv) -ne 1
        echo "No argument given"
        return
    end
    qrencode -o - $argv[1] | feh --geometry 500x500 --auto-zoom -
end

# System resource limiting
function limit --description "Limit process to specific CPU cores"
    numactl -C 0,1,2 $argv
end

# Terminal info for remote systems
function remote_alacritty --description "Set up alacritty terminfo on remote system"
    # https://gist.github.com/costis/5135502
    set fn (mktemp)
    infocmp alacritty > $fn
    scp $fn $argv[1]":alacritty.ti"
    ssh $argv[1] tic "alacritty.ti"
    ssh $argv[1] rm "alacritty.ti"
end

# =============================================================================
# PROMPT FUNCTIONS
# =============================================================================

function fish_prompt
    set_color brblack
    echo -n "["(date "+%H:%M")"] "
    set_color blue
    echo -n "aucker"
    if test $PWD != $HOME
        set_color brblack
        echo -n ':'
        set_color yellow
        echo -n (basename $PWD)
    end
    set_color green
    printf '%s ' (__fish_git_prompt)
    set_color red
    echo -n '| '
    set_color normal
end

function fish_greeting
    echo
    echo -e (uname -ro | awk '{print " \\e[1mOS: \\e[0;32m"$0"\\e[0m"}')
    echo -e (uptime | sed -E 's/.* up (.*), [0-9]+ users?.*/\1/' | awk '{print " \\e[1mUptime: \\e[0;32m"$0"\\e[0m"}')
    echo -e (uname -n | awk '{print " \\e[1mHostname: \\e[0;32m"$0"\\e[0m"}')

    set r (random 0 100)
    if test $r -lt 5 # only occasionally show backlog (5%)
        echo -e " \e[1mBacklog\e[0;32m"
        set_color blue
        echo "  [project] <description>"
        echo
    end

    set_color normal
    echo -e " \e[1mTODOs\e[0;32m"
    echo
    if test $r -lt 10
        # unimportant, so show rarely
        set_color cyan
        # echo "  [project] <description>"
    end
    if test $r -lt 25
        # back-of-my-mind, so show occasionally
        set_color green
        # echo "  [project] <description>"
    end
    if test $r -lt 50
        # upcoming, so prompt regularly
        set_color yellow
        # echo "  [project] <description>"
    end

    # urgent, so prompt always
    set_color red
    # echo "  [project] <description>"

    echo

    if test -s ~/todo
        set_color magenta
        cat ~/todo | sed 's/^/ /'
        echo
    end

    set_color normal
end
