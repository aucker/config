#!/bin/sh

# stow-posix.sh - POSIX-compliant dotfiles symlink manager
# A lightweight alternative to GNU Stow for managing configuration files

set -e

# Default configuration
DEFAULT_TARGET="${HOME}"
DRY_RUN=false
VERBOSE=false
TARGET="${DEFAULT_TARGET}"

# Script information
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"

# Help text and usage information
show_help() {
    cat << 'EOF'
stow-posix.sh - POSIX-compliant dotfiles symlink manager

SYNOPSIS
    stow-posix.sh [OPTIONS] COMMAND [ARGUMENTS...]

DESCRIPTION
    A lightweight, POSIX-sh-compatible tool for managing symbolic links to 
    configuration files and directories. Organizes dotfiles into packages 
    and categories for clean, maintainable configuration management.

COMMANDS
    install [all|CATEGORY|PACKAGE...]    Install packages/categories
    uninstall [all|CATEGORY|PACKAGE...]  Remove packages/categories  
    status                               Show installation status
    help                                 Show this help message

OPTIONS
    -n, --dry-run       Show what would be done without making changes
    -v, --verbose       Enable verbose output
    -t, --target DIR    Set target directory (default: $HOME)
    -h, --help          Show this help message
    --version           Show version information

PACKAGE STRUCTURE
    Packages are organized in the following directory structure:
    
    dotfiles/
    ├── category1/
    │   ├── package1/
    │   │   ├── .vimrc
    │   │   └── .vim/
    │   └── package2/
    │       └── .zshrc
    └── category2/
        └── package3/
            └── .gitconfig

CATEGORIES
    Categories are top-level directories that group related packages:
    
    - shell/          Shell configurations (bash, zsh, fish)
    - editor/         Editor configurations (vim, emacs, nano)
    - terminal/       Terminal emulator configurations
    - desktop/        Desktop environment configurations
    - development/    Development tool configurations
    - system/         System-level configurations
    - macos/          macOS-specific configurations
    - linux/          Linux-specific configurations

PACKAGE DETECTION
    Packages are automatically detected by scanning category directories.
    A package is any directory containing dotfiles (files/dirs starting with '.').
    
    Detection rules:
    - Files starting with '.' are considered dotfiles
    - Directories starting with '.' are considered dot-directories
    - Empty directories are ignored
    - Files without leading '.' are ignored (use for documentation)

CONFLICT HANDLING
    When installing packages, conflicts may arise:
    
    1. Existing regular files: Backed up with .bak extension
    2. Existing symlinks: 
       - If pointing to managed location: Updated
       - If pointing elsewhere: Backed up and replaced
    3. Existing directories:
       - If empty: Removed and replaced with symlink
       - If non-empty: Contents merged or backed up based on --force flag

EXAMPLES
    Basic usage:
        stow-posix.sh install shell/zsh
        stow-posix.sh uninstall editor/vim
        stow-posix.sh status

    Install entire categories:
        stow-posix.sh install shell
        stow-posix.sh install editor terminal

    Install everything:
        stow-posix.sh install all

    Dry run (preview changes):
        stow-posix.sh -n install shell/zsh
        stow-posix.sh --dry-run uninstall all

    Verbose output:
        stow-posix.sh -v install desktop/i3
        stow-posix.sh --verbose status

    Custom target directory:
        stow-posix.sh -t /etc install system/nginx
        stow-posix.sh --target /usr/local/etc install system/brew

    Platform-specific examples:
        # macOS
        stow-posix.sh install macos/homebrew
        stow-posix.sh install macos/defaults
        stow-posix.sh install terminal/iterm2
        
        # Linux
        stow-posix.sh install linux/systemd
        stow-posix.sh install desktop/i3
        stow-posix.sh install terminal/alacritty

    Combined operations:
        stow-posix.sh -v -t /home/user install shell editor
        stow-posix.sh --verbose --dry-run install all
        stow-posix.sh -n -t /tmp uninstall development/node

PLATFORM DIFFERENCES
    macOS considerations:
    - Uses BSD-style commands (different from GNU Linux)
    - Homebrew configurations typically in /usr/local or /opt/homebrew
    - System preferences in ~/Library/Preferences
    - Application support in ~/Library/Application Support

    Linux considerations:
    - Uses GNU-style commands
    - System configs typically in /etc
    - User configs in ~/.config following XDG Base Directory
    - Package manager configurations vary by distribution

EXIT STATUS
    0    Success
    1    General error
    2    Invalid command line arguments
    3    Package/category not found
    4    Permission denied
    5    Conflict resolution failed

ENVIRONMENT VARIABLES
    STOW_TARGET     Override default target directory
    STOW_VERBOSE    Enable verbose output (set to any value)
    STOW_DRY_RUN    Enable dry-run mode (set to any value)

FILES
    ~/.stow-posix.log    Operation log file (if verbose enabled)
    
AUTHOR
    stow-posix.sh - A POSIX-compliant dotfiles manager

SEE ALSO
    stow(8), ln(1), find(1)

EOF
}

# Version information
show_version() {
    echo "${SCRIPT_NAME} ${VERSION}"
    echo "POSIX-compliant dotfiles symlink manager"
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -t|--target)
                if [ -z "$2" ]; then
                    echo "Error: --target requires a directory argument" >&2
                    exit 2
                fi
                TARGET="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                echo "Try '${SCRIPT_NAME} --help' for more information." >&2
                exit 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Store remaining arguments
    COMMAND="$1"
    shift
    ARGS="$*"
}

# Verbose logging
log() {
    if [ "$VERBOSE" = true ]; then
        echo "INFO: $*" >&2
    fi
}

# Error logging
error() {
    echo "ERROR: $*" >&2
}

# Main command dispatcher
main() {
    if [ $# -eq 0 ]; then
        echo "Error: No command specified" >&2
        echo "Try '${SCRIPT_NAME} --help' for more information." >&2
        exit 2
    fi
    
    parse_args "$@"
    
    case "$COMMAND" in
        install)
            install_packages $ARGS
            ;;
        uninstall)
            uninstall_packages $ARGS
            ;;
        status)
            show_status
            ;;
        help)
            show_help
            ;;
        *)
            echo "Error: Unknown command: $COMMAND" >&2
            echo "Try '${SCRIPT_NAME} --help' for more information." >&2
            exit 2
            ;;
    esac
}

# Placeholder functions for actual implementation
install_packages() {
    log "Installing packages: $*"
    log "Target directory: $TARGET"
    log "Dry run: $DRY_RUN"
    echo "install_packages function not yet implemented"
}

uninstall_packages() {
    log "Uninstalling packages: $*"
    log "Target directory: $TARGET"
    log "Dry run: $DRY_RUN"
    echo "uninstall_packages function not yet implemented"
}

show_status() {
    log "Showing status for target: $TARGET"
    echo "show_status function not yet implemented"
}

# Run main function if script is executed directly
if [ "${0##*/}" = "stow-posix.sh" ]; then
    main "$@"
fi
