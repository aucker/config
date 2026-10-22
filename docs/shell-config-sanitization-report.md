# Shell Configuration Sanitization Report

**Date:** 2026-06-26  
**Scope:** fish, zsh, profile

---

## Problem

Opening fish shell directly resulted in `node: command not found`. Switching to
zsh first (where nvm loads node into PATH) and then back to fish "fixed" it —
because fish inherited the modified PATH from the zsh parent process.

**Root cause:** Fish doesn't source `.zshrc` or `.profile`, so it never learned
about the nvm node binary path. The fix is trivial (`fish_add_path` for the nvm
bin directory), but while auditing the configs I found several other issues worth
addressing.

---

## Changes Made

### `~/.config/fish/config.fish`

| Change | Rationale |
|--------|-----------|
| Added `fish_add_path $HOME/.nvm/versions/node/v22.19.0/bin` | **Fixes the node-not-found bug.** |
| Removed duplicate FZF initialization (`source (fzf --fish \| psub)` + `fzf --fish \| source`) | Only one is needed; kept the simpler `fzf --fish \| source` inside the interactive guard. |
| Changed `set -Ux` → `set -gx` for `FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`, `FZF_DEFAULT_OPTS` | `set -Ux` in config.fish rewrites the universal variable store on every shell startup. Universal vars should be set once interactively; config.fish should use global-export (`-gx`). |
| Removed trailing `set -gx PATH "/home/asus/.local/bin" $PATH` (Antigravity installer) | Already handled by `fish_add_path $HOME/.local/bin` above. Duplicate causes PATH pollution in nested shells. |
| Changed CUDA `LD_LIBRARY_PATH` from `cuda-13.0` to `/usr/local/cuda/lib64` | Uses the managed symlink — survives CUDA upgrades without config edits. |
| Consolidated PATH section with a comment header | Readability. |

### `fish_user_paths` (universal variable)

| Change | Rationale |
|--------|-----------|
| Removed `/usr/local/cuda-12.8/bin` | Stale — system has moved to CUDA 13.0. |
| Removed `/usr/local/cuda-13.0/bin` | Replaced by generic `/usr/local/cuda/bin` symlink (added via `fish_add_path -p`). |
| Erased universal `FZF_DEFAULT_COMMAND`, `FZF_CTRL_T_COMMAND`, `FZF_DEFAULT_OPTS` | Now set as global-export in config.fish; leftover universals would shadow/conflict. |

### `~/.zshrc`

| Change | Rationale |
|--------|-----------|
| Removed `export NPM_CONFIG_PREFIX="$HOME/.nvm/versions/node/v22.19.0"` | Redundant — `nvm.sh` (loaded below) manages this dynamically. Hardcoding a version here breaks on `nvm use`/`nvm install`. |
| Removed `export PATH="/home/asus/.nvm/versions/node/v22.19.0/bin:$PATH"` | Same reason — `nvm.sh` adds the active node version to PATH. |
| Changed `cuda-12.8` → `/usr/local/cuda` for both `PATH` and `LD_LIBRARY_PATH` | Aligns with fish config; uses the managed symlink. |
| Removed `[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh` | Duplicate of `source <(fzf --zsh)` on the next line. Kept the modern form. |
| Removed trailing `export PATH="/home/asus/.local/bin:$PATH"` (Antigravity installer) | Duplicate of line 13. |

### `~/.zshenv`

| Change | Rationale |
|--------|-----------|
| Removed `export PATH="/Users/aucker/Library/Python/3.12/bin:$PATH"` | macOS path on a Linux/WSL machine — the directory doesn't exist and pollutes PATH. |

### `~/.profile`

| Change | Rationale |
|--------|-----------|
| Removed trailing `export PATH="/home/asus/.local/bin:$PATH"` (Antigravity installer) | Already handled by the conditional block at line 25. |

### `~/.config/zsh/function.zsh`

| Change | Rationale |
|--------|-----------|
| Changed `alias ga="git add -A"` → `alias ga="git add -p"` | Was silently overwritten by `fish_compat.zsh` (sourced later). Now both files agree — no hidden conflict. |
| Changed `alias gc="git commit -v"` → `alias gc="git checkout"` | Same as above. Matches fish config semantics. |

---

## Verification

```
$ env -i HOME=/home/asus PATH=/usr/bin:/bin fish -c 'which node'
/home/asus/.nvm/versions/node/v22.19.0/bin/node   ✓

$ fish -c 'source ~/.config/fish/config.fish'      # exit 0, no errors ✓
$ zsh -c 'source ~/.zshenv && source ~/.zshrc'     # exit 0, no errors ✓
```

---

## Note for Future

If you upgrade node via `nvm install <new-version>`, update the fish path:

```fish
# In ~/.config/fish/config.fish, change:
fish_add_path $HOME/.nvm/versions/node/v22.19.0/bin
# to:
fish_add_path $HOME/.nvm/versions/node/v<NEW_VERSION>/bin
```

Alternatively, consider [nvm.fish](https://github.com/jorgebucaran/nvm.fish) or
[fnm](https://github.com/Schniz/fnm) (which has native fish support) to avoid
hardcoding versions entirely.
