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
./bin/dotfiles install all
```

This will set up the most commonly used configurations in your environment. 

## How to Add a New Package

To add a new package, create it under `packages/`, add its name to the relevant
file under `profiles/`, and install it with the unified dotfiles command:

```bash
mkdir -p packages/mypkg
./bin/dotfiles install mypkg
```

## Example Screenshots

Here's a status output example showing installed packages:

```text
PACKAGE                            STATUS          DETAILS
-------                            ------          -------
git                                installed       4/4 linked, 0 missing, 0 conflicts
zsh                                installed       6/6 linked, 0 missing, 0 conflicts
nvim                               installed       2/2 linked, 0 missing, 0 conflicts
```

## CI Badges

[![CI](https://github.com/aucker/config/actions/workflows/ci.yml/badge.svg)](https://github.com/aucker/config/actions/workflows/ci.yml) [![Shellcheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/aucker/config/actions/workflows/ci.yml) [![shfmt](https://img.shields.io/badge/shfmt-formatted-blue)](https://github.com/aucker/config/actions/workflows/ci.yml)

## Installation

### Unix-like Systems (Linux, macOS, WSL)

Use the unified dotfiles command. `all` selects `profiles/macos`,
`profiles/linux`, or `profiles/wsl` based on the current platform:

```bash
./bin/dotfiles install all
```

Preview an operation or inspect package state without changing files:

```bash
./bin/dotfiles --dry-run install @macos
./bin/dotfiles status all
```

Host-specific shell paths and environment values are deliberately untracked.
After installing, copy the relevant example and customize it locally:

```bash
cp ~/.config/fish/local.fish.example ~/.config/fish/local.fish
cp ~/.config/zsh/local.zsh.example ~/.config/zsh/local.zsh
```

The shared Fish and Zsh configurations load these files when present.

### Windows

Windows users should use the dedicated PowerShell script:

```powershell
.\stow-windows.ps1
```

This script reads the explicit `profiles/windows` selection, handles its
Windows-specific configurations from the `windows/` directory, and creates
symbolic links to the appropriate Windows locations:

- PowerShell profile → `$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- Starship config → `$env:USERPROFILE\.config\starship.toml`
- VS Code settings → `$env:APPDATA\Code\User\`

**Note:** `bin/dotfiles` manages POSIX packages only and deliberately rejects
`@windows`. Native Windows configurations use `stow-windows.ps1`.

## Directory Structure

- `packages/` - Flat GNU Stow packages such as `git`, `zsh`, and `nvim`
- `profiles/` - Explicit macOS, Linux, WSL, and Windows selections
- `scripts/` - Utilities that are run directly rather than stowed
- `docs/` - Notes and archived configuration references
- `windows/` - Windows-only configurations (handled by `stow-windows.ps1`)
