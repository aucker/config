# Dotfiles Repository Structure

This repository follows a standardized layout for GNU Stow packages with four main categories:

## Directory Structure

```
.
├── shell/          # Shell configurations and utilities
├── editor/         # Text editors and IDEs
├── terminal/       # Terminal emulators
├── server/         # Server applications and services
└── windows/        # Windows-specific configurations (ignored by Stow)
```

## Naming Conventions

Each category contains one GNU Stow package per logical tool using dashed, human-readable names:

### Shell Category
- `shell/shell-bash/` - Bash shell configuration
- `shell/shell-fish/` - Fish shell configuration
- `shell/shell-zsh/` - Zsh shell configuration
- `shell/shell-git/` - Git configuration and aliases
- `shell/shell-zsh-plugins/` - Zsh plugins and extensions

### Editor Category
- `editor/editor-nvim/` - Neovim configuration
- `editor/editor-vim/` - Vim configuration
- `editor/editor-vscode/` - Visual Studio Code configuration
- `editor/editor-emacs/` - Emacs configuration

### Terminal Category
- `terminal/terminal-alacritty/` - Alacritty terminal emulator
- `terminal/terminal-kitty/` - Kitty terminal emulator
- `terminal/terminal-wezterm/` - WezTerm terminal emulator

### Server Category
- `server/server-fish/` - Fish shell server configurations
- `server/server-nginx/` - Nginx server configuration
- `server/server-apache/` - Apache server configuration

## Windows Support

The `windows/` directory contains Windows-specific configurations and is ignored by the Stow scripts to prevent conflicts with POSIX installations.

## Stow Usage

To install a specific package:
```bash
stow -t ~ shell/shell-bash
stow -t ~ editor/editor-nvim
stow -t ~ terminal/terminal-alacritty
```

To install all packages in a category:
```bash
stow -t ~ shell/*
stow -t ~ editor/*
```

## Ignore Files

The `.stow-local-ignore` file prevents Windows-specific files and common backup files from being processed by Stow, ensuring clean installations on POSIX systems.
