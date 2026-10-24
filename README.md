# Personal dotfiles

macOS-first configuration with explicit Linux, WSL, and native Windows selections.
POSIX files are GNU Stow packages managed by `bin/dotfiles`; native Windows uses
`stow-windows.ps1`.

[![CI](https://github.com/aucker/config/actions/workflows/ci.yml/badge.svg)](https://github.com/aucker/config/actions/workflows/ci.yml)

## Start here

Install Git, Bash, and GNU Stow first. On macOS with an existing Homebrew installation:

```bash
brew install git stow
git clone https://github.com/aucker/config.git "$HOME/config"
cd "$HOME/config"
./bin/dotfiles list
./bin/dotfiles --dry-run install all
./bin/dotfiles install all
./bin/dotfiles status all
```

`all` selects the detected macOS, Linux, or WSL profile. Review the preview and
resolve conflicts first. Stow links files into your home; it does not install
the applications referenced by those files. Select fewer packages, such as
`install git zsh`, when the full profile is unnecessary.

The checkout is the live source of your linked configs. Editing a package takes
effect through its home-directory symlink. Keep the checkout at a stable path;
see [bootstrap and rollback](docs/bootstrap.md) before moving it or adopting files.

## Commands and profiles

Run these from the checkout, or invoke its `bin/dotfiles` by an absolute path
from another directory. Options precede the subcommand.

```bash
./bin/dotfiles install git zsh
./bin/dotfiles --dry-run install @linux
./bin/dotfiles status all
./bin/dotfiles --dry-run uninstall tmux
./bin/dotfiles uninstall tmux
./bin/dotfiles help
```

| Profile | Selection |
| --- | --- |
| `@macos` | core, git, zsh, fish, tmux, vim, nvim, vscode-macos, alacritty |
| `@linux` | core, git, zsh, fish, tmux, vim, nvim, alacritty |
| `@wsl` | core, git, zsh, fish, tmux, vim, nvim |
| Native Windows | powershell, starship, vscode via `profiles/windows` and `stow-windows.ps1` |

The POSIX command rejects `@windows`. The Windows script is install-only;
parity and testing are deferred. Profiles isolate target paths, but some
application behavior still has [platform assumptions](docs/bootstrap.md#application-dependencies-and-limitations).

## Local settings and secrets

Keep these regular files in your home configuration directory, outside the
Stow packages. Installed examples show the available settings.

| Local file | Purpose |
| --- | --- |
| `~/.config/fish/local.fish` | Host paths and Fish environment settings |
| `~/.config/zsh/local.zsh` | Host paths and Zsh environment settings |
| `~/.config/git/config.local` | Identity, signing, proxy, and Git account settings |
| `~/.config/fish/secrets.local.fish` | Variable-to-password-store mappings |
| `~/.config/zsh/secrets.local.zsh` | Variable-to-password-store mappings |

Configure only the shells you use. Git reads its optional local include last.
Secret mappings contain store references, never raw credentials; values load
from macOS Keychain or `pass`. See [local setup](docs/bootstrap.md#local-settings)
and [secret provisioning](docs/secrets.md).

The managed Git hook checks this repository's staged changes with Gitleaks after
any C formatting. Install Python 3 and Gitleaks before committing; the hook blocks
commits if scanning cannot run. CI also scans current files and new commits.
Reports hide credential values.

## Verification and maintenance

```bash
./tests/test-dotfiles.sh
bash tests/test-secret-loading.sh
python3 -B tests/test_runtime_portability.py
python3 scripts/check_secrets.py worktree
python3 -B tests/test_secret_scanning.py
```

The [validation guide](docs/validation.md) lists dependencies, format checks, CI
coverage, and the optional full-history audit. Installation tests use temporary
targets, not your real home. Syntax checks do not establish runtime compatibility
of every editor plugin or host-specific command.

To add a package, create `packages/NAME/` with paths relative to the target home,
add `NAME` to the appropriate profiles, and update `tests/fixtures/managed-files.tsv`
plus expected profile selections in `tests/test-dotfiles.sh`. Run the checks
before committing. Keep generated state, host overrides, and credentials out of packages.

See [repository structure](STRUCTURE.md) for package ownership and
[the roadmap](ARCHITECTURE_ROADMAP.md) for completed and deferred work. Previous
implementation reports are preserved in [the archive](docs/archive/README.md).

## Inspiration

[geohot](https://github.com/geohot/configuration),
[jonhoo](https://github.com/jonhoo/configs),
and [laixintao](https://github.com/laixintao/myrc).
