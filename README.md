# <3 configs

Some useful and cool config for reference...

1. [geohot](https://github.com/geohot/configuration)
2. [jonhoo](https://github.com/jonhoo/configs)
3. [laixintao](https://github.com/laixintao/myrc)
4. ...

## Quick Start

To get started quickly, clone the repository and run the installation script:

```bash
git clone git@github.com:aucker/config.git
cd config
./stow-install.sh
```

This will set up the most commonly used configurations in your environment. 

## How to Add a New Package

To add a new package, create a directory for it in the appropriate category and install it using `stow-posix.sh`:

```bash
mkdir -p shell/mypkg
./stow-posix.sh install shell/mypkg
```

## Example Screenshots

Here's a status output example showing installed packages:

```
Category             Package                        Status         
========             =======                        ======         
./editor             editor-nvim                    installed
./server             server-fish                    installed
./shell              shell-fish                     installed
./shell              shell-git                      installed
./terminal           terminal-alacritty             installed

Legend:
  installed   - All package files are symlinked
  partially  - Some package files are symlinked
  not installed - No package files are symlinked
```

## CI Badges

[![CI](https://github.com/aucker/config/actions/workflows/ci.yml/badge.svg)](https://github.com/aucker/config/actions/workflows/ci.yml) [![Shellcheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/aucker/config/actions/workflows/ci.yml) [![shfmt](https://img.shields.io/badge/shfmt-formatted-blue)](https://github.com/aucker/config/actions/workflows/ci.yml)

## Installation

### Unix-like Systems (Linux, macOS, WSL)

Use the main stow installation script:

```bash
./stow-install.sh
```

This script will install dotfiles from the `shell/`, `editor/`, `terminal/`, and `server/` directories using GNU Stow.

### Windows

Windows users should use the dedicated PowerShell script:

```powershell
.\stow-windows.ps1
```

This script handles Windows-specific configurations from the `windows/` directory and creates symbolic links to the appropriate Windows locations:

- PowerShell profile → `$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- Starship config → `$env:USERPROFILE\.config\starship.toml`
- VS Code settings → `$env:APPDATA\Code\User\`

**Note:** The main `stow-install.sh` script ignores the `windows/` directory completely and includes a guard to prevent execution in Windows environments.

## Directory Structure

- `shell/` - Shell configurations (fish, git, etc.)
- `editor/` - Editor configurations (nvim, vscode, etc.)
- `terminal/` - Terminal configurations (alacritty, etc.)
- `server/` - Server-specific configurations
- `windows/` - Windows-only configurations (handled by `stow-windows.ps1`)

