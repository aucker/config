# Ported from Fish config

# Abbreviations as Aliases
alias yr='cal -y'
alias m='make'
alias an='antigravity'
alias o='xdg-open'
alias gc='git checkout'
alias ga='git add -p'
alias vimdiff='nvim -d'
alias ct='cargo t'
alias amz='env AWS_SECRET_ACCESS_KEY=$(pass www/aws-secret-key | head -n1)'
alias ais="aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | {iid: .InstanceId, type: .InstanceType, key:.KeyName, state:.State.Name, host:.PublicDnsName}'"
alias gah='git stash && git pull --rebase && git stash pop'
alias ks='keybase chat send'
alias kr='keybase chat read'
alias kl='keybase chat list'
alias pr='gh pr create -t $(git show -s --format=%s HEAD) -b $(git show -s --format=%B HEAD | tail -n+3)'
alias nova='env OS_PASSWORD=$(pass www/mit-openstack | head -n1) nova'
alias glance='env OS_PASSWORD=$(pass www/mit-openstack | head -n1) glance'

# Functions
function pwl() {
    export OP_SESSION_my=$(pw signin my --raw)
}

function ssh() {
    case "$1" in
        *.amazonaws.com|ubuntu@*)
            TERM=xterm /usr/bin/ssh "$@"
            ;;
        *)
            /usr/bin/ssh "$@"
            ;;
    esac
}

function apass() {
    if [ $# -ne 1 ]; then
        pass "$@"
        return
    fi
    asend $(pass "$1" | head -n1)
}

function qrpass() {
    if [ $# -ne 1 ]; then
        pass "$@"
        return
    fi
    qrsend $(pass "$1" | head -n1)
}

function asend() {
    if [ $# -ne 1 ]; then
        echo "No argument given"
        return
    fi
    adb shell input text $(echo "$1" | sed -e 's/ /%s/g' -e 's/\([#[()<>{}$|;&*\\~"'\''`]\)/\\\\\1/g')
}

function qrsend() {
    if [ $# -ne 1 ]; then
        echo "No argument given"
        return
    fi
    qrencode -o - "$1" | feh --geometry 500x500 --auto-zoom -
}

function limit() {
    numactl -C 0,1,2 "$@"
}

function remote_alacritty() {
    local fn=$(mktemp)
    infocmp alacritty > "$fn"
    scp "$fn" "$1":alacritty.ti
    ssh "$1" tic "alacritty.ti"
    ssh "$1" rm "alacritty.ti"
}

function remarkable() {
    if [ $# -lt 1 ]; then
        echo "No files given"
        return
    fi

    ip addr show up to 10.11.99.0/29 | grep enp0s20f0u2 >/dev/null
    if [ $? -ne 0 ]; then
        echo "Connecting to reMarkable internal network"
        sudo dhcpcd enp0s20f0u2
    fi
    for f in "$@"; do
        echo "-> uploading $f"
        curl --form "file=@\"$f\"" http://10.11.99.1/upload
        echo
    done
    sudo dhcpcd -k enp2s0f0u3
}

# Type - to move up to top parent dir which is a repository
function d() {
    while [ "$PWD" != "/" ]; do
        if [ -d .git ]; then
            break
        fi
        cd ..
    done
}

function penv() {
    env OS_PASSWORD=$(pass www/mit-openstack | head -n1) OS_TENANT_NAME=pdos OS_PROJECT_NAME=pdos "$@"
}

function pvm() {
    case "$1" in
        image-*)
            penv glance "$@"
            ;;
        c)
            penv cinder "${@:2}"
            ;;
        g)
            penv glance "${@:2}"
            ;;
        *)
            penv nova "$@"
            ;;
    esac
}

# Greeting
function zsh_greeting() {
    print
    print -P " %BOS: %F{green}$(uname -ro)%f%b"
    print -P " %BUptime: %F{green}$(uptime -p | sed 's/^up //')%f%b"
    print -P " %BHostname: %F{green}$(uname -n)%f%b"
    print -P " %BDisk usage:%b"
    print
    df -l -h | grep -E 'dev/(xvda|sd|mapper)' | \
        awk '{printf "\t%s\t%4s / %4s  %s\n", $6, $3, $2, $5}' | \
        while read line; do
            if [[ $line =~ ([8][5-9]|[9][0-9])% ]]; then
                print -P "%F{red}$line%f"
            elif [[ $line =~ ([7][5-9]|[8][0-4])% ]]; then
                print -P "%F{yellow}$line%f"
            else
                print -l "\t$line"
            fi
        done
    print

    print -P " %BNetwork:%b"
    print
    ip addr show up scope global | \
        grep -E ': <|inet' | \
        sed \
            -e 's/^[[:digit:]]\+: //' \
            -e 's/: <.*//' \
            -e 's/.*inet[[:digit:]]* //' \
            -e 's/\/.*//'| \
        awk 'BEGIN {i=""} /\.|:/ {print i" "$0"\n"; next} // {i = $0}' | \
        sort | \
        column -t -R1 | \
        while read line; do
            # underlined public addresses
            local processed_line=$(echo "$line" | sed 's/ \([^ ]\+\)$/ \x1b[4m\1\x1b[24m/')
            # color coding based on interface type
            if [[ $line =~ ^( *lo) ]]; then
                print -l "\t$line"
            elif [[ $line =~ ^( *en|em|eth) ]]; then
                print -P "\t%F{39}$processed_line%f"
            elif [[ $line =~ ^( *wl) ]]; then
                print -P "\t%F{35}$processed_line%f"
            elif [[ $line =~ ^( *ww) ]]; then
                print -P "\t%F{33}$processed_line%f"
            else
                print -P "\t%F{36}$processed_line%f"
            fi
        done
    print

    local r=$(( RANDOM % 100 ))
    if [ $r -lt 5 ]; then
        print -P " %BBacklog%F{green}%b"
        print -P "%F{blue}  [project] <description>%f"
        print
    fi

    print -P " %BTODOs%F{green}%b"
    print
    if [ $r -lt 10 ]; then
        print -P "%F{cyan}  [project] <description>%f"
    fi
    if [ $r -lt 25 ]; then
        print -P "%F{green}  [project] <description>%f"
    fi
    if [ $r -lt 50 ]; then
        print -P "%F{yellow}  [project] <description>%f"
    fi

    print -P "%F{red}  [project] <description>%f"
    print

    if [ -s ~/todo ]; then
        print -P "%F{magenta}$(cat ~/todo | sed 's/^/ /')%f"
        print
    fi
}
