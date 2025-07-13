#!/bin/bash
# Quick stow status checker

echo "Stow Package Status:"
echo "===================="

packages=("fish" "git" "nvim" "vscode" "alacritty")

for package in "${packages[@]}"; do
    if [ -d "$package" ]; then
        # Check if any files from this package are symlinked
        if find ~/.config ~/Library/Application\ Support/Code/User -type l 2>/dev/null | while read -r link; do readlink "$link"; done 2>/dev/null | grep -q "config/$package/"; then
            echo "✅ $package"
        else
            echo "❌ $package"
        fi
    else
        echo "❓ $package (directory not found)"
    fi
done
