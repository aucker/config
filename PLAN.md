# Dotfiles Refactoring Plan

Based on our discussion, here is the plan to clean up and refactor the dotfiles repository:

## 1. Consolidate and Clean Up Fish Configurations
**Goal:** Resolve the messy, redundant fish configurations between the `server` and `shell` categories.

- **Action:** Merge the contents of `server/server-fish` into `shell/shell-fish`.
- **Implementation:**
  - Create a single, unified `shell/shell-fish/.config/fish/config.fish` file.
  - Introduce OS-detection logic (using `uname`) within `config.fish` to conditionally apply macOS-specific (Homebrew paths) vs. Linux-specific (CUDA, LLVM paths) configurations.
  - Consolidate all functions into `shell/shell-fish/.config/fish/functions/`.
  - Safely delete the redundant `server/server-fish` directory (which currently contains 3 duplicated versions of `config.fish`).
  - Safely delete the entire `server/` category if it becomes empty.

## 2. Introduce a 'Core' Package
**Goal:** Ensure root-level configuration files are properly managed and symlinked by GNU Stow.

- **Action:** Create a new category and package: `core/core-config/`.
- **Implementation:**
  - Move `.clang-format` and `.editorconfig` from the repository root into `core/core-config/`.
  - This allows users to install these global formats via `./stow-posix.sh install core/core-config`.

## 3. Remove Clutter
**Goal:** Remove unused template files to keep the repository focused.

- **Action:** Delete sample directories.
- **Implementation:**
  - Remove `editor/editor-sample/`.
  - Remove `shell/shell-sample/`.
  - Remove `terminal/terminal-sample/`.

## 4. Zsh Path Corrections
**Goal:** Ensure the Zsh configuration works reliably when symlinked by Stow.

- **Action:** Reorganize Zsh auxiliary files.
- **Implementation:**
  - Currently, files like `function.zsh` and `fish_compat.zsh` sit in the root of `shell/shell-zsh/` and get stowed directly to the user's home directory (`~/function.zsh`), which is messy.
  - Move these helper files into a dedicated `shell/shell-zsh/.zsh/` directory.
  - Update `shell/shell-zsh/.zshrc` to source them correctly from `~/.zsh/`.

## 5. Documentation Updates
**Goal:** Keep documentation in sync with reality.

- **Action:** Update `STRUCTURE.md` and `README.md`.
- **Implementation:**
  - Reflect the removal of `server` (if empty) and `*-sample` directories.
  - Document the new `core/` category.
