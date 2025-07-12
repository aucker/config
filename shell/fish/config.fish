function fzf_history
    history | fzf | read -l line
    commandline $line
end

bind \cr fzf_history

abbr -a yr 'cal -y'
abbr -a c cargo
abbr -a e nvim
abbr -a vi nvim
abbr -a m make
abbr -a g git
abbr -a gc 'git checkout'
abbr -a ga 'git add -p'
abbr -a vimdiff 'nvim -d'
abbr -a ct 'cargo t'
abbr -a amz 'env AWS_SECRET_ACCESS_KEY=(pass www/aws-secret-key | head -n1)'
abbr -a ais "aws ec2 describe-instances | jq '.Reservations[] | .Instances[] | {iid: .InstanceId, type: .InstanceType, key:.KeyName, state:.State.Name, host:.PublicDnsName}'"
abbr -a gah 'git stash; and git pull --rebase; and git stash pop'
abbr -a ks 'keybase chat send'
abbr -a kr 'keybase chat read'
abbr -a kl 'keybase chat list'
abbr -a pr 'gh pr create -t (git show -s --format=%s HEAD) -b (git show -s --format=%B HEAD | tail -n+3)'
complete --command aurman --wraps pacman
complete --command paru --wraps pacman

if status --is-interactive
	if test -d ~/dev/others/base16/templates/fish-shell
		set fish_function_path $fish_function_path ~/dev/others/base16/templates/fish-shell/functions
		builtin source ~/dev/others/base16/templates/fish-shell/conf.d/base16.fish
	end
	switch $TERM
		case 'linux'
			:
		case '*'
			if ! set -q TMUX
				exec tmux
			end
	end
end

if command -v eza > /dev/null
	abbr -a l 'eza'
	abbr -a ls 'eza'
	abbr -a ll 'eza -l'
	abbr -a lll 'eza -la'
else
	abbr -a l 'ls'
	abbr -a ll 'ls -l'
	abbr -a lll 'ls -la'
end

if test -f /usr/share/autojump/autojump.fish;
	source /usr/share/autojump/autojump.fish;
end

#Set PDM env
set -gx PATH /Users/aucker/Library/Python/3.13/bin $PATH

set -gx EDITOR nvim

# Executes a command after a countdown
# Usage: countdown <seconds> <command...>
function countdown --description "Run a command after a countdown"
	# Use argparse for robust argument handling
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
	set -l cmd_to_run $argv[2..-1] # The rest of the arguments from the countdown

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

function pwl
	set -Ux OP_SESSION_my (pw signin my --raw)
end

function ssh
	switch $argv[1]
	case "*.amazonaws.com"
		env TERM=xterm /usr/bin/ssh $argv
	case "ubuntu@"
		env TERM=xterm /usr/bin/ssh $argv
	case "*"
		/usr/bin/ssh $argv
	end
end

function apass
	if test (count $argv) -ne 1
		pass $argv
		return
	end

	asend (pass $argv[1] | head -n1)
end

function qrpass
	if test (count $argv) -ne 1
		pass $argv
		return
	end

	qrsend (pass $argv[1] | head -n1)
end

function asend
	if test (count $argv) -ne 1
		echo "No argument given"
		return
	end

	adb shell input text (echo $argv[1] | sed -e 's/ /%s/g' -e 's/\([#[()<>{}$|;&*\\~"\'`]\)/\\\\\1/g')
end

function qrsend
	if test (count $argv) -ne 1
		echo "No argument given"
		return
	end

	qrencode -o - $argv[1] | feh --geometry 500x500 --auto-zoom -
end

function limit
	numactl -C 0,1,2 $argv
end

function remote_alacritty
	# https://gist.github.com/costis/5135502
	set fn (mktemp)
	infocmp alacritty > $fn
	scp $fn $argv[1]":alacritty.ti"
	ssh $argv[1] tic "alacritty.ti"
	ssh $argv[1] rm "alacritty.ti"
end

function remarkable
	if test (count $argv) -lt 1
		echo "No files given"
		return
	end

	ip addr show up to 10.11.99.0/29 | grep enp0s20f0u2 >/dev/null
	if test $status -ne 0
		# not yet connected
		echo "Connecting to reMarkable internal network"
		sudo dhcpcd enp0s20f0u2
	end
	for f in $argv
		echo "-> uploading $f"
		curl --form "file=@\""$f"\"" http://10.11.99.1/upload
		echo
	end
	sudo dhcpcd -k enp2s0f0u3
end

# Type - to move up to top parent dir which is a repository
function d
	while test $PWD != "/"
		if test -d .git
			break
		end
		cd ..
	end
end

# Fish git prompt
set __fish_git_prompt_showuntrackedfiles 'yes'
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate ''
set __fish_git_prompt_showupstream 'none'
set -g fish_prompt_pwd_dir_length 3

# colored man output
# from http://linuxtidbits.wordpress.com/2009/03/23/less-colors-for-man-pages/
setenv LESS_TERMCAP_mb \e'[01;31m'       # begin blinking
setenv LESS_TERMCAP_md \e'[01;38;5;74m'  # begin bold
setenv LESS_TERMCAP_me \e'[0m'           # end mode
setenv LESS_TERMCAP_se \e'[0m'           # end standout-mode
setenv LESS_TERMCAP_so \e'[38;5;246m'    # begin standout-mode - info box
setenv LESS_TERMCAP_ue \e'[0m'           # end underline
setenv LESS_TERMCAP_us \e'[04;38;5;146m' # begin underline

setenv FZF_DEFAULT_COMMAND 'fd --type file --follow'
setenv FZF_CTRL_T_COMMAND 'fd --type file --follow'
setenv FZF_DEFAULT_OPTS '--height 20%'

function fish_user_key_bindings
	bind \cz 'fg>/dev/null ^/dev/null'
	if functions -q fzf_key_bindings
		fzf_key_bindings
	end
end

function fish_prompt
	set_color brblack
	echo -n "["(date "+%H:%M")"] "
	set_color blue
	#echo -n (scutil --get HostName)
    echo -n "aucker"
	if [ $PWD != $HOME ]
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
	echo -e (uname -ro | awk '{print " \\\\e[1mOS: \\\\e[0;32m"$0"\\\\e[0m"}')
	echo -e (uptime | sed -E 's/.* up (.*), [0-9]+ users?.*/\1/' | awk '{print " \\\\e[1mUptime: \\\\e[0;32m"$0"\\\\e[0m"}')
	echo -e (uname -n | awk '{print " \\\\e[1mHostname: \\\\e[0;32m"$0"\\\\e[0m"}')
	#echo -e " \\e[1mDisk usage:\\e[0m"
	#echo
	#echo -ne (\
	#	df -l -h | grep -E 'dev/(xvda|sd|mapper)' | \
	#	awk '{printf "\\\\t%s\\\\t%4s / %4s  %s\\\\n\n", $6, $3, $2, $5}' | \
	#	sed -e 's/^\(.*\([8][5-9]\|[9][0-9]\)%.*\)$/\\\\e[0;31m\1\\\\e[0m/' -e 's/^\(.*\([7][5-9]\|[8][0-4]\)%.*\)$/\\\\e[0;33m\1\\\\e[0m/' | \
	#	paste -sd ''\
	#)
	#   echo -ne "$( \
	#       df -l -h | \
	#       grep '^/dev/disk' | \
	#       awk '{printf "\\\\t%s\\\\t%4s / %4s  %s\\\\n", $9, $3, $2, $5}' | \
	#       sed -e 's/^\(.*\([8][5-9]\|[9][0-9]\)%.*\)$/\\\\e[0;31m\1\\\\e[0m/' \
	#           -e 's/^\(.*\([7][5-9]\|[8][0-4]\)%.*\)$/\\\\e[0;33m\1\\\\e[0m/' | \
	#       tr -d '\n' \
	#   )"
	#echo

	#echo -e " \\e[1mNetwork:\\e[0m"
	#echo
	# http://tdt.rocks/linux_network_interface_naming.html
	#echo -ne (\
	#	ifconfig | \
	#		grep -E ': <|inet' | \
	#		sed \
	#			-e 's/^[[:digit:]]\+: //' \
	#			-e 's/: <.*//' \
	#			-e 's/.*inet[[:digit:]]* //' \
	#			-e 's/\/.*//'| \
	#		awk 'BEGIN {i=""} /\.|:/ {print i" "$0"\\\n"; next} // {i = $0}' | \
	#		sort | \
	#		column -t | \
	#		# public addresses are underlined for visibility \
	#		sed 's/ \([^ ]\+\)$/ \\\e[4m\1/' | \
	#		# private addresses are not \
	#		sed 's/m\(\(10\.\|172\.\(1[6-9]\|2[0-9]\|3[01]\)\|192\.168\.\).*\)/m\\\e[24m\1/' | \
	#		# unknown interfaces are cyan \
	#		sed 's/^\( *[^ ]\+\)/\\\e[36m\1/' | \
	#		# ethernet interfaces are normal \
	#		sed 's/\(\(en\|em\|eth\)[^ ]* .*\)/\\\e[39m\1/' | \
	#		# wireless interfaces are purple \
	#		sed 's/\(wl[^ ]* .*\)/\\\e[35m\1/' | \
	#		# wwan interfaces are yellow \
	#		sed 's/\(ww[^ ]* .*\).*/\\\e[33m\1/' | \
	#		sed 's/$/\\\e[0m/' | \
	#		sed 's/^/\t/' \
	#	)
	#echo

	set r (random 0 100)
	if [ $r -lt 5 ] # only occasionally show backlog (5%)
		echo -e " \e[1mBacklog\e[0;32m"
		set_color blue
		echo "  [project] <description>"
		echo
	end

	set_color normal
	echo -e " \e[1mTODOs\e[0;32m"
	echo
	if [ $r -lt 10 ]
		# unimportant, so show rarely
		set_color cyan
		# echo "  [project] <description>"
	end
	if [ $r -lt 25 ]
		# back-of-my-mind, so show occasionally
		set_color green
		# echo "  [project] <description>"
	end
	if [ $r -lt 50 ]
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
		cat todo | sed 's/^/ /'
		echo
	end

	set_color normal
end

zoxide init fish | source
