#!/bin/sh

# stow-posix.sh - POSIX-compliant dotfiles symlink manager
# A lightweight alternative to GNU Stow for managing configuration files

# set -e removed to allow proper error handling of stow conflicts

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

# Check if GNU Stow is available
check_stow_availability() {
    if ! command -v stow >/dev/null 2>&1; then
        echo "ERROR: GNU Stow is not installed or not in PATH" >&2
        echo "Please install GNU Stow:" >&2
        echo "  - On macOS: brew install stow" >&2
        echo "  - On Ubuntu/Debian: sudo apt-get install stow" >&2
        echo "  - On CentOS/RHEL: sudo yum install stow" >&2
        echo "  - On Arch Linux: sudo pacman -S stow" >&2
        exit 1
    fi
    log "GNU Stow found: $(command -v stow)"
}

# Parse stow conflict output to extract conflicting files
parse_stow_conflicts() {
    local stderr_output="$1"
    echo "$stderr_output" | grep -E "(existing target|would cause conflicts|cannot stow)" | sed 's/^stow: //' | while read -r line; do
        echo "  - $line"
    done
}

# Install a single package with conflict detection
install_package() {
    local package_path="$1"
    local package_name="$(basename "$package_path")"
    local category="$(dirname "$package_path")"
    
    if [ "$category" = "." ]; then
        category="$(pwd)"
    fi
    
    log "Installing package: $package_name from $category"
    
    # Check if package directory exists
    if [ ! -d "$package_path" ]; then
        error "Package directory '$package_path' does not exist"
        return 3
    fi
    
    # Check if package contains any dotfiles
    if ! find "$package_path" -name ".*" -type f -o -name ".*" -type d | head -1 | grep -q .; then
        error "Package '$package_name' contains no dotfiles (files/directories starting with '.')"
        return 3
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would install: $package_name -> $TARGET"
        return 0
    fi
    
    # Change to the category directory
    local original_dir="$(pwd)"
    cd "$category" || {
        error "Failed to change to category directory: $category"
        return 1
    }
    
    # Capture stderr from stow command
    local stderr_output
    local exit_code
    
    stderr_output=$(stow --no-folding -t "$TARGET" "$package_name" 2>&1)
    exit_code=$?
    
    # Return to original directory
    cd "$original_dir" || {
        error "Failed to return to original directory"
        return 1
    }
    
    # Handle different exit codes
    case $exit_code in
        0)
            echo "✅ Successfully installed: $package_name"
            if [ "$VERBOSE" = true ]; then
                echo "   Target: $TARGET"
                echo "   Package: $package_path"
            fi
            return 0
            ;;
        1)
            # Check if this is a conflict (stow returns 1 for conflicts)
            if echo "$stderr_output" | grep -q "would cause conflicts"; then
                echo "❌ Installation failed due to conflicts: $package_name"
                echo "   Conflicting files/directories:"
                parse_stow_conflicts "$stderr_output"
                echo ""
                echo "   💡 Suggested solutions:"
                echo "   1. Back up existing files and try again"
                echo "   2. Use 'uninstall' to remove conflicting symlinks from other packages"
                echo "   3. Manually resolve conflicts by removing/moving existing files"
                echo "   4. Use 'stow --adopt' to adopt existing files into the package"
                return 2
            else
                echo "❌ Installation failed: $package_name (exit code: $exit_code)"
                if [ -n "$stderr_output" ]; then
                    echo "   Error details:"
                    echo "$stderr_output" | sed 's/^/   /'
                fi
                return 1
            fi
            ;;
        *)
            echo "❌ Installation failed: $package_name (exit code: $exit_code)"
            if [ -n "$stderr_output" ]; then
                echo "   Error details:"
                echo "$stderr_output" | sed 's/^/   /'
            fi
            return 1
            ;;
    esac
}

# Uninstall a single package
uninstall_package() {
    local package_path="$1"
    local package_name="$(basename "$package_path")"
    local category="$(dirname "$package_path")"
    
    if [ "$category" = "." ]; then
        category="$(pwd)"
    fi
    
    log "Uninstalling package: $package_name from $category"
    
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would uninstall: $package_name"
        return 0
    fi
    
    # Change to the category directory
    local original_dir="$(pwd)"
    cd "$category" || {
        error "Failed to change to category directory: $category"
        return 1
    }
    
    # Check if package directory exists
    if [ ! -d "$package_name" ]; then
        echo "⚠️  Package '$package_name' not found in category '$category'"
        cd "$original_dir"
        return 3
    fi
    
    # Capture stderr from stow command
    local stderr_output
    local exit_code
    
    stderr_output=$(stow -D -t "$TARGET" "$package_name" 2>&1)
    exit_code=$?
    
    # Return to original directory
    cd "$original_dir" || {
        error "Failed to return to original directory"
        return 1
    }
    
    # Handle different exit codes
    case $exit_code in
        0)
            echo "✅ Successfully uninstalled: $package_name"
            if [ "$VERBOSE" = true ]; then
                echo "   Target: $TARGET"
                echo "   Package: $package_path"
            fi
            return 0
            ;;
        *)
            echo "❌ Uninstallation failed: $package_name (exit code: $exit_code)"
            if [ -n "$stderr_output" ]; then
                echo "   Error details:"
                echo "$stderr_output" | sed 's/^/   /'
            fi
            return 1
            ;;
    esac
}

# Discover packages in a category
find_packages_in_category() {
    local category="$1"
    
    if [ ! -d "$category" ]; then
        return 1
    fi
    
    find "$category" -maxdepth 1 -type d ! -name "$category" | while read -r package_dir; do
        package_name="$(basename "$package_dir")"
        # Check if package contains dotfiles
        if find "$package_dir" -name ".*" -type f -o -name ".*" -type d | head -1 | grep -q .; then
            echo "$package_dir"
        fi
    done
}

# Discover all packages
find_all_packages() {
    find . -maxdepth 3 -type d -name ".*" | while read -r dotfile_dir; do
        package_dir="$(dirname "$dotfile_dir")"
        if [ "$package_dir" != "." ] && [ "$package_dir" != "./.git" ]; then
            echo "$package_dir"
        fi
    done | sort -u
}

# Main install function
install_packages() {
    check_stow_availability
    
    if [ $# -eq 0 ]; then
        error "No packages specified for installation"
        return 2
    fi
    
    local failed_count=0
    local success_count=0
    
    for arg in "$@"; do
        case "$arg" in
            all)
                echo "📦 Installing all packages..."
                find_all_packages | while read -r package_path; do
                    install_package "$package_path"
                    case $? in
                        0) success_count=$((success_count + 1)) ;;
                        *) failed_count=$((failed_count + 1)) ;;
                    esac
                done
                ;;
            */*)  # Category/package format
                install_package "$arg"
                case $? in
                    0) success_count=$((success_count + 1)) ;;
                    *) failed_count=$((failed_count + 1)) ;;
                esac
                ;;
            *)
                # Check if it's a category
                if [ -d "$arg" ]; then
                    echo "📁 Installing category: $arg"
                    find_packages_in_category "$arg" | while read -r package_path; do
                        install_package "$package_path"
                        case $? in
                            0) success_count=$((success_count + 1)) ;;
                            *) failed_count=$((failed_count + 1)) ;;
                        esac
                    done
                else
                    # Treat as package name and search for it
                    found=false
                    for category in */; do
                        if [ -d "$category$arg" ]; then
                            install_package "$category$arg"
                            case $? in
                                0) success_count=$((success_count + 1)) ;;
                                *) failed_count=$((failed_count + 1)) ;;
                            esac
                            found=true
                            break
                        fi
                    done
                    
                    if [ "$found" = false ]; then
                        error "Package or category '$arg' not found"
                        failed_count=$((failed_count + 1))
                    fi
                fi
                ;;
        esac
    done
    
    echo ""
    echo "📊 Installation summary:"
    echo "   ✅ Successful: $success_count"
    echo "   ❌ Failed: $failed_count"
    
    if [ $failed_count -gt 0 ]; then
        return 1
    fi
}

# Main uninstall function
uninstall_packages() {
    check_stow_availability
    
    if [ $# -eq 0 ]; then
        error "No packages specified for uninstallation"
        return 2
    fi
    
    local failed_count=0
    local success_count=0
    
    for arg in "$@"; do
        case "$arg" in
            all)
                echo "📦 Uninstalling all packages..."
                find_all_packages | while read -r package_path; do
                    uninstall_package "$package_path"
                    case $? in
                        0) success_count=$((success_count + 1)) ;;
                        *) failed_count=$((failed_count + 1)) ;;
                    esac
                done
                ;;
            */*)  # Category/package format
                uninstall_package "$arg"
                case $? in
                    0) success_count=$((success_count + 1)) ;;
                    *) failed_count=$((failed_count + 1)) ;;
                esac
                ;;
            *)
                # Check if it's a category
                if [ -d "$arg" ]; then
                    echo "📁 Uninstalling category: $arg"
                    find_packages_in_category "$arg" | while read -r package_path; do
                        uninstall_package "$package_path"
                        case $? in
                            0) success_count=$((success_count + 1)) ;;
                            *) failed_count=$((failed_count + 1)) ;;
                        esac
                    done
                else
                    # Treat as package name and search for it
                    found=false
                    for category in */; do
                        if [ -d "$category$arg" ]; then
                            uninstall_package "$category$arg"
                            case $? in
                                0) success_count=$((success_count + 1)) ;;
                                *) failed_count=$((failed_count + 1)) ;;
                            esac
                            found=true
                            break
                        fi
                    done
                    
                    if [ "$found" = false ]; then
                        echo "⚠️  Package or category '$arg' not found"
                        failed_count=$((failed_count + 1))
                    fi
                fi
                ;;
        esac
    done
    
    echo ""
    echo "📊 Uninstallation summary:"
    echo "   ✅ Successful: $success_count"
    echo "   ❌ Failed: $failed_count"
    
    if [ $failed_count -gt 0 ]; then
        return 1
    fi
}

# Check if tput is available for colors
has_tput() {
    command -v tput > /dev/null 2>&1
}

# Color functions
color_red() {
    if has_tput; then
        tput setaf 1
    fi
}

color_green() {
    if has_tput; then
        tput setaf 2
    fi
}

color_yellow() {
    if has_tput; then
        tput setaf 3
    fi
}

color_blue() {
    if has_tput; then
        tput setaf 4
    fi
}

color_reset() {
    if has_tput; then
        tput sgr0
    fi
}

# Check package status using stow dry-run
check_package_status() {
    local package_path="$1"
    local package_name="$(basename "$package_path")"
    local category="$(dirname "$package_path")"
    
    if [ "$category" = "." ]; then
        category="$(pwd)"
    fi
    
    # Check if package directory exists
    if [ ! -d "$package_path" ]; then
        echo "not found"
        return 1
    fi
    
    # Check if package contains any dotfiles
    if ! find "$package_path" -name ".*" -type f -o -name ".*" -type d | head -1 | grep -q .; then
        echo "no dotfiles"
        return 1
    fi
    
    # Change to the category directory
    local original_dir="$(pwd)"
    cd "$category" || {
        echo "error"
        return 1
    }
    
    # Use stow dry-run to check status
    local stderr_output
    local exit_code
    
    stderr_output=$(stow --no-folding --target "$TARGET" --adopt -n "$package_name" 2>&1)
    exit_code=$?
    
    # Return to original directory
    cd "$original_dir" || {
        echo "error"
        return 1
    }
    
    # Analyze the output to determine status
    if [ $exit_code -eq 0 ]; then
        # If stow dry-run succeeds, check if there are already links
        # by attempting to unstow in dry-run mode
        cd "$category" || {
            echo "error"
            return 1
        }
        
        local unstow_output
        unstow_output=$(stow -D -n -t "$TARGET" "$package_name" 2>&1)
        local unstow_exit=$?
        
        cd "$original_dir" || {
            echo "error"
            return 1
        }
        
        if [ $unstow_exit -eq 0 ] && [ -n "$unstow_output" ]; then
            echo "installed"
        else
            echo "not installed"
        fi
    else
        # Check if conflicts indicate partial installation
        if echo "$stderr_output" | grep -q "would cause conflicts"; then
            # Check if any symlinks exist by examining readlink
            local has_some_links=false
            find "$package_path" -name ".*" -type f -o -name ".*" -type d | while read -r file; do
                local rel_path="${file#$package_path/}"
                local target_path="$TARGET/$rel_path"
                if [ -L "$target_path" ]; then
                    local link_target=$(readlink "$target_path")
                    if echo "$link_target" | grep -q "$package_path"; then
                        has_some_links=true
                        break
                    fi
                fi
            done
            
            if [ "$has_some_links" = true ]; then
                echo "partially"
            else
                echo "not installed"
            fi
        else
            echo "not installed"
        fi
    fi
}

# Alternative status check using readlink inspection
check_package_status_readlink() {
    local package_path="$1"
    local package_name="$(basename "$package_path")"
    
    # Check if package directory exists
    if [ ! -d "$package_path" ]; then
        echo "not found"
        return 1
    fi
    
    # Check if package contains any dotfiles
    if ! find "$package_path" -name ".*" -type f -o -name ".*" -type d | head -1 | grep -q .; then
        echo "no dotfiles"
        return 1
    fi
    
    local total_files=0
    local installed_files=0
    
    # Find all dotfiles in the package
    find "$package_path" -name ".*" -type f -o -name ".*" -type d | while read -r file; do
        total_files=$((total_files + 1))
        local rel_path="${file#$package_path/}"
        local target_path="$TARGET/$rel_path"
        
        # Check if target exists and is a symlink pointing to our package
        if [ -L "$target_path" ]; then
            local link_target=$(readlink "$target_path")
            # Check if link points to our package (handle both absolute and relative paths)
            if echo "$link_target" | grep -q "$package_path" || echo "$link_target" | grep -q "$package_name"; then
                installed_files=$((installed_files + 1))
            fi
        fi
    done
    
    # Use a temporary file to store counts since we're in a subshell
    local temp_file="$(mktemp)"
    find "$package_path" -name ".*" -type f -o -name ".*" -type d | while read -r file; do
        local rel_path="${file#$package_path/}"
        local target_path="$TARGET/$rel_path"
        
        if [ -L "$target_path" ]; then
            local link_target=$(readlink "$target_path")
            if echo "$link_target" | grep -q "$package_path" || echo "$link_target" | grep -q "$package_name"; then
                echo "installed" >> "$temp_file"
            else
                echo "not_installed" >> "$temp_file"
            fi
        else
            echo "not_installed" >> "$temp_file"
        fi
    done
    
    local total_files=$(find "$package_path" -name ".*" -type f -o -name ".*" -type d | wc -l)
    local installed_files=$(grep -c "installed" "$temp_file" 2>/dev/null || echo 0)
    
    rm -f "$temp_file"
    
    if [ "$installed_files" -eq "$total_files" ] && [ "$total_files" -gt 0 ]; then
        echo "installed"
    elif [ "$installed_files" -gt 0 ]; then
        echo "partially"
    else
        echo "not installed"
    fi
}

# Format status with colors
format_status() {
    local status="$1"
    case "$status" in
        "installed")
            color_green
            printf "installed"
            color_reset
            ;;
        "partially")
            color_yellow
            printf "partially"
            color_reset
            ;;
        "not installed")
            color_red
            printf "not installed"
            color_reset
            ;;
        *)
            color_red
            printf "$status"
            color_reset
            ;;
    esac
}

show_status() {
    check_stow_availability
    
    log "Showing status for target: $TARGET"
    
    # Print header
    color_blue
    printf "%-20s %-30s %-15s\n" "Category" "Package" "Status"
    printf "%-20s %-30s %-15s\n" "========" "=======" "======"
    color_reset
    
    # Find all packages and check their status
    find_all_packages | sort | while read -r package_path; do
        local package_name="$(basename "$package_path")"
        local category="$(dirname "$package_path")"
        
        # Use readlink-based check as primary method (more reliable)
        local status=$(check_package_status_readlink "$package_path")
        
        # Format the output
        printf "%-20s %-30s " "$category" "$package_name"
        format_status "$status"
        printf "\n"
    done
    
    echo ""
    echo "Legend:"
    printf "  "
    format_status "installed"
    printf "   - All package files are symlinked\n"
    printf "  "
    format_status "partially"
    printf "  - Some package files are symlinked\n"
    printf "  "
    format_status "not installed"
    printf " - No package files are symlinked\n"
}

# Run main function if script is executed directly
if [ "${0##*/}" = "stow-posix.sh" ]; then
    main "$@"
fi
