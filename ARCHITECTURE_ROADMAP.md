# Dotfiles Architecture Roadmap

This roadmap records the architecture review of this repository. Choose an item
by its ID when deciding what to work on next.

## Current Status

- [x] **SEC-01 — Disable and remove the exposed Gemini API key**
  - Removed the key assignment from the Fish working tree.
  - Google reports the old key as leaked and rejects it with
    `PERMISSION_DENIED`, so it no longer grants API access.
  - The unrelated API key visible in Google AI Studio was not changed.
- [x] **SEC-02 — Remove the disabled key from Git history**
  - Rewrote all local refs and verified that the old key has zero matches in
    reachable history.
  - Force-pushed the rewritten `main` and `wip` branches using explicit leases.
  - Existing clones should be replaced or carefully realigned with the new
    history because the affected commit IDs changed.

## Priority 1: Make Installation Reliable

- [x] **INST-01 — Consolidate the POSIX entry points**
  - Replace `stow-install.sh`, `stow-status.sh`, `stow-quick-status.sh`, and
    `stow-adopt.sh` with one supported Bash command.
  - Keep install, uninstall, status, dry-run, and help as subcommands.
  - Make the command work regardless of the caller's current directory.

- [x] **INST-02 — Repair error and conflict handling**
  - Prevent `set -e` from terminating before Stow errors can be reported.
  - Return consistent exit codes and show actionable conflict information.
  - Make dry-run invoke GNU Stow simulation instead of only printing messages.

- [x] **INST-03 — Replace automatic package discovery with explicit profiles**
  - Add explicit package lists for macOS, Linux, and WSL.
  - Ensure `core-config`, Vim, VS Code, and future packages cannot be silently
    omitted because of their directory shape.
  - Fix success and failure counters that currently run in pipeline subshells.

- [x] **INST-04 — Rebuild package status checks**
  - Check managed files rather than counting dotted directories.
  - Correct the match that currently counts `not_installed` as `installed`.
  - Test fully installed, partially installed, conflicting, and absent states.

- [x] **INST-05 — Make adoption safe**
  - Require an explicit package instead of adopting everything.
  - Refuse to run with an unexpectedly dirty worktree.
  - Preview changes, create a recoverable backup, and display the resulting
    Git diff.

## Priority 2: Normalize Repository Structure

- [x] **PKG-01 — Put every managed file inside a package**
  - Added packages for `.tmux.conf` and the Git pre-commit hook.
  - Archived the obsolete, host-specific `.zshrc_linux` rather than installing
    it alongside the active Zsh package.
  - Confirmed that the previously noted `init.lua.jonhoo` is not present.

- [x] **PKG-02 — Simplify the package hierarchy**
  - Use one predictable package root, for example:

    ```text
    packages/
      core/
      git/
      fish/
      zsh/
      tmux/
      vim/
      nvim/
      alacritty/
    ```

  - Keep platform-specific packages separate when their target paths differ.
  - Flattened every managed package under `packages/`; the macOS-specific VS
    Code target is named `vscode-macos`.

- [x] **PKG-03 — Repair the Alacritty theme dependency**
  - The theme directory is recorded as a Git submodule, but `.gitmodules` is
    missing.
  - Preferred option: vendor only the selected theme file.
  - Alternative: restore a valid, pinned submodule definition.
  - Replaced the broken theme gitlink with the one selected theme file and
    updated Alacritty to import that vendored path.

- [x] **PKG-04 — Remove generated and machine-state files**
  - Review whether Fish `fish_variables` should remain tracked.
  - Keep `.DS_Store`, caches, transient editor state, and generated files out
    of packages.
  - Removed tracked Fish universal-variable state and ignored it along with
    `.DS_Store` files.

## Priority 3: Separate Shared, Platform, Host, and Secret State

- [x] **PORT-01 — Introduce platform profiles**
  - Define macOS, Linux, WSL, and Windows package selections explicitly.
  - Prevent a Linux installation from creating macOS `~/Library` paths.
  - Added a native Windows selection consumed by `stow-windows.ps1`; the POSIX
    command rejects it with an explicit handoff.
  - Added regression coverage proving that the Linux profile excludes macOS
    `~/Library` targets.

- [x] **PORT-02 — Move host-specific paths out of shared shell files**
  - Remove fixed usernames, WSL paths, CUDA versions, compiler locations, and
    other machine-specific paths from the shared Fish and Zsh configuration.
  - Load an ignored local override file for each machine.
  - Added untracked `local.fish` and `local.zsh` hooks with safe examples.
  - Moved pinned toolchain, CUDA, PostgreSQL, proxy, and repository paths out
    of the shared shell startup files.

- [x] **PORT-03 — Split shared and local Git configuration**
  - Keep aliases, diff settings, and defaults in the repository.
  - Move identity, signing key, proxy, and machine-dependent settings to an
    included local configuration.
  - Added an optional, final `config.local` include and a commented setup
    example; migrated this Mac's settings while preserving their values.

- [x] **SEC-03 — Standardize secret loading**
  - Use macOS Keychain, `pass`, or 1Password rather than tracked shell files.
  - Provide documented helper functions without storing secret values.
  - Add an example local-secrets file containing names only, never values.
  - Added matching Fish/Zsh loaders for Keychain and `pass`, with optional
    reference-only local mapping files and offline failure-path tests.
  - Migrated this Mac's Anthropic token into Keychain, verified it, and removed
    the plaintext Git-config fallback.

- [ ] **WIN-01 — Give Windows command parity**
  - Add status, dry-run, uninstall, and consistent conflict handling to the
    PowerShell installer.
  - Keep Windows path mappings explicit and testable.
  - Deferred at the user's request; no Windows runtime or tests are required
    for the current macOS/Linux verification work.

## Priority 4: Verification and Documentation

- [x] **TEST-01 — Add real Stow integration tests**
  - Install into a temporary home directory in CI.
  - Verify every expected symlink.
  - Exercise conflicts, partial installs, uninstall, and idempotent re-runs.
  - Verify macOS, Linux, and WSL profile links against an independent fixture,
    including paths with spaces and preservation of local files on uninstall.
  - Run integration tests on both Linux and macOS CI runners.

- [x] **TEST-02 — Validate configuration formats (POSIX scope)**
  - Check Bash, POSIX sh, Zsh, Fish, Lua, TOML, YAML, strict JSON, VS Code
    JSONC, Git configuration, and the Python validation tools.
  - Parse every shell file individually, including local-file examples; use
    Zsh's native parser rather than passing Zsh files to ShellCheck.
  - Compile Lua in Neovim without executing the configuration or plugins.
  - Add parser regression tests and run validation in macOS/Linux CI.
  - PowerShell validation remains deferred alongside WIN-01.

- [x] **TEST-03 — Add secret scanning**
  - Reject newly committed API keys, private keys, passwords, and common cloud
    credentials.
  - Maintain a small allowlist for deliberate variable names and examples.
  - Added Gitleaks staged/worktree/history checks with value-free findings,
    exact placeholder exemptions, and real-scanner regression tests.
  - Integrated staged checks into the managed Git hook; CI scans current files
    and newly pushed/PR commits using a checksum-verified pinned scanner.

- [ ] **SEC-04 — Rotate the historically exposed WakaTime API key (deferred)**
  - Full-history scanning found the same key in VS Code settings in commits
    `326cca0` and `38f7075`; it is absent from current files.
  - Stopped at the user's request because WakaTime is no longer used. No key
    rotation or WakaTime history rewrite was performed; revocation is unverified.
  - Full-history scans retain the finding without an exemption or baseline.

- [x] **DOC-01 — Replace stale documentation**
  - Rewrite `README.md` around the actual bootstrap and profile workflow.
  - Update or replace `STRUCTURE.md`.
  - Archive or delete obsolete implementation notes after useful decisions are
    incorporated.
  - Replaced README/structure guidance and archived the old plan, removed
    installer's implementation report, and earlier shell sanitization report.

- [x] **DOC-02 — Document bootstrap dependencies**
  - List required and optional tools for each operating system.
  - Document fresh-machine installation, rollback, local overrides, and secret
    provisioning.
  - Added focused bootstrap and validation guides with actual command behavior,
    dependency groups, backup recovery, and remaining runtime portability limits.

## Runtime portability follow-up

- [x] **RUN-01 — Make the Fish greeting platform-aware**
  - Preserve macOS metrics; add Linux memory/disk/network/battery fallbacks and
    graceful placeholders when tools or platform data are unavailable.
  - Use a private per-user cache and the platform's native `stat` syntax.
- [x] **RUN-02 — Select clipboard backends at runtime**
  - Use native Neovim clipboard providers, and a tmux helper for macOS,
    Wayland, or X11; preserve text when a clipboard backend is unavailable.
- [x] **RUN-03 — Remove Vim's version-pinned formatter path**
  - Resolve `clang-format` from PATH, format unsaved content through stdin,
    and preserve the buffer on missing tools or failed formatting.
- [x] **RUN-04 — Exercise runtime branches without a second machine**
  - Add offline fixtures plus native Neovim/Vim and private-server tmux tests
    to the macOS/Linux CI matrix.

## Remaining scope

The POSIX installation, package normalization, local-state separation, verification,
and documentation work above is complete. `WIN-01` (including PowerShell validation)
and `SEC-04` are deferred at the user's request. Reopen them only when requested.
Application-specific runtime portability assumptions remain documented in
[the bootstrap guide](docs/bootstrap.md#application-dependencies-and-limitations).
