#!/bin/bash
# Script to safely adopt existing configurations into stow packages

echo "Adopting existing configurations into stow packages..."

# Function to safely adopt a package
adopt_package() {
    local category=$1
    local package=$2
    echo "Adopting $category/$package..."
    
    # Change to category directory
    cd "$category" || return 1
    
    # Try to adopt the package
    local output
    local exit_code
    
    output=$(stow --adopt -v -t ~ "$package" 2>&1)
    exit_code=$?
    
    # Return to root directory
    cd ..
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ $category/$package adopted successfully"
        echo "$output" | grep "LINK:"
    else
        echo "❌ Failed to adopt $category/$package"
        echo "$output"
    fi
    
    return $exit_code
}

# Adopt shell packages
if [ -d "shell" ]; then
    echo "📁 Adopting shell packages..."
    adopt_package "shell" "shell-fish"
    adopt_package "shell" "shell-git"
    echo ""
fi

# Adopt editor packages
if [ -d "editor" ]; then
    echo "📁 Adopting editor packages..."
    adopt_package "editor" "editor-nvim"
    adopt_package "editor" "editor-vscode"
    echo ""
fi

# Adopt terminal packages
if [ -d "terminal" ]; then
    echo "📁 Adopting terminal packages..."
    adopt_package "terminal" "terminal-alacritty"
    echo ""
fi

echo "Adoption complete!"
echo ""
echo "NOTE: After adoption, you should check the packages for any changes"
echo "      and commit them to preserve your current configurations."
