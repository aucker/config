#!/bin/bash
# Stow installation script for dotfiles

echo "Installing dotfiles with Stow..."

# Function to install a package with proper error handling
install_package() {
    local category=$1
    local package=$2
    echo "Installing $category/$package..."
    
    # Change to category directory and run stow
    cd "$category" || return 1
    
    # Capture both stdout and stderr
    local output
    local exit_code
    
    output=$(stow -v -t ~ "$package" 2>&1)
    exit_code=$?
    
    # Return to root directory
    cd ..
    
    # Check if there were conflicts
    if echo "$output" | grep -q "WARNING.*would cause conflicts"; then
        echo "⚠️  $category/$package has conflicts:"
        echo "$output" | grep -E "(WARNING|cannot stow|existing target)"
        echo "   You may need to:"
        echo "   1. Backup existing files"
        echo "   2. Use 'stow --adopt $package' to adopt existing files"
        echo "   3. Or manually resolve conflicts"
        return 1
    elif [ $exit_code -eq 0 ]; then
        echo "✅ $category/$package installed successfully"
        # Show what was linked
        echo "$output" | grep "LINK:"
        return 0
    else
        echo "❌ Failed to install $category/$package"
        echo "$output"
        return 1
    fi
}

# Install shell packages
if [ -d "shell" ]; then
    echo "📁 Processing shell category..."
    for package in shell-fish shell-git; do
        if [ -d "shell/$package" ]; then
            install_package "shell" "$package"
        else
            echo "⚠️  Package directory 'shell/$package' not found, skipping..."
        fi
        echo "" # Empty line for readability
    done
fi

# Install editor packages
if [ -d "editor" ]; then
    echo "📁 Processing editor category..."
    for package in editor-nvim editor-vscode; do
        if [ -d "editor/$package" ]; then
            install_package "editor" "$package"
        else
            echo "⚠️  Package directory 'editor/$package' not found, skipping..."
        fi
        echo "" # Empty line for readability
    done
fi

# Install terminal packages
if [ -d "terminal" ]; then
    echo "📁 Processing terminal category..."
    for package in terminal-alacritty; do
        if [ -d "terminal/$package" ]; then
            install_package "terminal" "$package"
        else
            echo "⚠️  Package directory 'terminal/$package' not found, skipping..."
        fi
        echo "" # Empty line for readability
    done
fi

# Install server packages
if [ -d "server" ]; then
    echo "📁 Processing server category..."
    for package in server-fish; do
        if [ -d "server/$package" ]; then
            install_package "server" "$package"
        else
            echo "⚠️  Package directory 'server/$package' not found, skipping..."
        fi
        echo "" # Empty line for readability
    done
fi

echo "All packages processed!"
