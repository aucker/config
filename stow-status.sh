#!/bin/bash
# Stow status script for dotfiles

echo "Checking Stow package status..."
echo "================================="

# List of packages to check
packages=(
    "shell/shell-fish"
    "shell/shell-git"
    "editor/editor-nvim"
    "editor/editor-vscode"
    "terminal/terminal-alacritty"
)

# Function to check if a package is stowed
check_package_status() {
    local package=$1
    local stowed=false
    local links_found=()
    
    if [ ! -d "$package" ]; then
        echo "❌ $package: Package directory not found"
        return
    fi
    
    # Find all files in the package directory
    while IFS= read -r -d '' file; do
        # Get the relative path from the package directory
        local rel_path="${file#$package/}"
        local target_path="$HOME/$rel_path"
        
        # Check if the target exists and is a symlink pointing to our file
        if [ -L "$target_path" ]; then
            local link_target=$(readlink "$target_path")
            if [[ "$link_target" == *"config/$package"* ]]; then
                stowed=true
                links_found+=("$rel_path")
            fi
        fi
    done < <(find "$package" -type f -print0)
    
    if [ "$stowed" = true ]; then
        echo "✅ $package: STOWED"
        echo "   Symlinks found:"
        for link in "${links_found[@]}"; do
            echo "   - $link"
        done
    else
        echo "❌ $package: NOT STOWED"
    fi
    echo ""
}

# Check each package
for package in "${packages[@]}"; do
    check_package_status "$package"
done

# Show summary of all symlinks pointing to this config repo
echo "================================="
echo "All symlinks pointing to this config repo:"
echo "================================="

# Find all symlinks in common locations that point to this config repo
find ~/.config ~/Library/Application\ Support/Code/User -type l 2>/dev/null | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == *"config/"* ]]; then
        echo "$link -> $target"
    fi
done
