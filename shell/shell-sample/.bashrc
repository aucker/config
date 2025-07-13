# Sample .bashrc configuration
# This is a demo file to show the shell category structure

# Set up path
export PATH="$HOME/.local/bin:$PATH"

# Useful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# Custom prompt
PS1='\u@\h:\w\$ '

echo "Sample shell configuration loaded!"
