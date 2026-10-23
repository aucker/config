# Bootstrap and rollback

## Dependencies

The installer manages links. It does not install applications, shell plugins,
fonts, language servers, or credentials.

| Task | Required tools |
| --- | --- |
| Clone/manage POSIX links | Git, Bash 3.2+, GNU Stow, standard Unix utilities |
| Use shell/editor configs | Corresponding applications and invoked integrations; see below |
| Commit here with the managed hook | Python 3 and Gitleaks; `clang-format` for staged `.c`/`.h` files |
| Profile integration tests | Git, Bash, GNU Stow |
| All local validation | Python 3.11+, pinned Python requirements, Fish, Zsh, Neovim, Git, Bash, GNU Stow, Gitleaks |
| CI shell lint/format checks locally | ShellCheck and shfmt in addition to the above |
| Native Windows install | PowerShell and permission to create symlinks; parity/testing deferred |

On macOS, use an existing [Homebrew installation](https://brew.sh/):

```bash
brew install git stow
# Add runtimes for the packages and checks you intend to use:
brew install fish zsh tmux neovim python gitleaks
```

Homebrew documents the install commands for [Stow](https://formulae.brew.sh/formula/stow)
and [Gitleaks](https://formulae.brew.sh/formula/gitleaks). The bundled macOS Bash
is sufficient for `bin/dotfiles`.

On Debian/Ubuntu, including WSL distributions using apt:

```bash
sudo apt-get update
sudo apt-get install -y git stow bash
# Optional runtimes and validation tools:
sudo apt-get install -y fish zsh tmux neovim python3 python3-venv
```

Check `python3 --version` before format validation: it requires 3.11+ for the
standard-library TOML parser. Older distributions need a newer Python.
Install Gitleaks separately from its [official releases](https://github.com/gitleaks/gitleaks/releases);
CI pins 8.30.1 and verifies its archive checksum. Other Linux distributions can
use equivalent packages from their own package manager.

## Fresh checkout and installation

Choose an unused checkout path, rather than cloning over an existing repository:

```bash
git clone https://github.com/aucker/config.git "$HOME/config"
cd "$HOME/config"
./bin/dotfiles list
./bin/dotfiles --dry-run install all
```

Review the detected profile and conflicts. Select an explicit profile or fewer
packages if appropriate:

```bash
./bin/dotfiles --dry-run install @macos
./bin/dotfiles --dry-run install git zsh
```

Then apply your chosen selection and inspect the result:

```bash
./bin/dotfiles install all
./bin/dotfiles status all
```

`install` continues across packages and returns failure if any package fails.
There is no whole-profile transaction or automatic rollback. A conflicting
package is not partially stowed. Existing regular files and foreign links are
reported rather than overwritten. Back them up and move them aside, or use
adoption below when their contents should become the shared version.

`status` reports installed, partial, missing, conflicting, or absent packages.
Its exit code reports inspection errors, not whether every package is installed;
inspect the rows and conflict counts.

For a disposable trial target instead of your real home:

```bash
trial_target=$(mktemp -d)
./bin/dotfiles --target "$trial_target" install @macos
./bin/dotfiles --target "$trial_target" status @macos
./bin/dotfiles --target "$trial_target" uninstall @macos
```

This leaves the temporary target for inspection; remove that exact directory
when finished. `--target` and `DOTFILES_TARGET` change the link target, not the
profile selection. Use `@linux` or `@wsl` explicitly when needed.

## Local settings

Examples are installed beside the corresponding configuration. Copy only the
ones you need. `cp -i` prompts before replacing an existing local file:

```bash
cp -i ~/.config/fish/local.fish.example ~/.config/fish/local.fish
cp -i ~/.config/zsh/local.zsh.example ~/.config/zsh/local.zsh
cp -i ~/.config/git/config.local.example ~/.config/git/config.local
chmod 600 ~/.config/git/config.local
```

Edit shell files for this host's paths, tool versions, and proxy behavior. They
are sourced early during startup. The samples include personal macOS paths;
review them instead of assuming those tools are installed.

Set your Git name/email in `~/.config/git/config.local`. Configure a signing key
after installing/importing it, then enable `commit.gpgsign` if desired. Configure
a proxy only where it exists. The example's settings are commented out: they do
not supply an identity or enable signing by default.

Keep local files in the target home, outside the checkout's Stow packages. They
survive uninstall and need separate backups. Follow [secret provisioning](secrets.md)
for Keychain/`pass` and optional `secrets.local.fish`/`secrets.local.zsh` mappings.
Do not put credentials in examples or Git configuration.

Open a fresh terminal after setup. Linked configs may be read immediately or
when an application reloads them. Editing through a home-directory symlink also
changes the repository file.

## Adoption and rollback

Adoption replaces package contents with conflicting live files, then links the
target back to the package. Start with a clean worktree and select one package.
Commit or otherwise preserve your existing changes first:

```bash
git status --short
./bin/dotfiles --dry-run adopt tmux
./bin/dotfiles --yes adopt tmux
git diff -- packages/tmux
```

The command previews the transaction, backs up package files and existing target
paths, and prints the backup location and resulting diff. The default backup
root is `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups`;
`DOTFILES_BACKUP_DIR` selects an alternative private location. Review the diff
before committing. Adoption dirties the worktree, so checkpoint one package
before adopting another.

To remove managed links:

```bash
./bin/dotfiles --dry-run uninstall tmux
./bin/dotfiles uninstall tmux
# Or select the same full profile used for installation:
./bin/dotfiles --dry-run uninstall all
./bin/dotfiles uninstall all
```

Uninstall preserves package sources, local overrides, and unrelated links.
Empty directories can remain. It does not undo adoption's content changes or
restore pre-existing files: use the printed backup's `package/` and `target/`
copies for recovery after reviewing exactly what should be restored. Check for
newer local work before copying any backup over it.

Before moving this checkout, uninstall affected links from the old location,
move the repository, and reinstall from the new location. To undo a shared
configuration change, preserve current work and restore/revert the intended
package revision; existing links expose the restored files immediately. No
automatic history rewrite is part of rollback.

## Application dependencies and limitations

Install the applications for the packages you select: Fish/Zsh, tmux,
Vim/Neovim, Alacritty, or VS Code. `EDITOR` is set to Neovim. Fish auto-starts
tmux for matching Kitty/Alacritty/Ghostty terminal types, so install tmux before
using that startup path. Zsh also has conditional tmux auto-start behavior.

Invoked integrations include `fzf`, `fd`, `rg`, Git LFS, and optional `eza`,
`zoxide`, and Starship. Install the ones you use; the installer does not
bootstrap them. External Zsh plugin files under `~/.local/share/zsh/` are
sourced only when present. Install Alacritty's selected font separately.
Neovim fetches lazy.nvim on first launch, and Vim may fetch vim-plug; starting
editors can therefore access the network.

Profiles separate target paths, not every application behavior. The Fish greeting
uses macOS utilities, tmux clipboard bindings use `xclip`, Neovim clipboard
mappings use `pbcopy`/`pbpaste`, and Vim has a pinned Homebrew clang-format
Python-script path. Review/adapt these on other hosts; link and syntax checks
do not establish full runtime portability. A non-macOS Fish user can define an
empty `fish_greeting` function in their local override to suppress that greeting.

## Native Windows

`stow-windows.ps1` reads `profiles/windows` and maps sources in `windows/` to
`USERPROFILE`/`APPDATA`. It currently installs links only and skips existing
targets. Status, dry-run, uninstall, consistent failure reporting, and runtime
testing are deferred. It is outside this POSIX bootstrap and the validation
commands above; this guide does not ask you to run it.
