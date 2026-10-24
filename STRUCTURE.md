# Repository structure

```text
config/
├── bin/dotfiles               # Supported POSIX management command
├── packages/                  # Flat GNU Stow package root
│   ├── core/
│   ├── git/
│   ├── zsh/
│   ├── fish/
│   ├── tmux/
│   ├── vim/
│   ├── nvim/
│   ├── vscode-macos/
│   └── alacritty/
├── profiles/                  # macos, linux, wsl, windows
├── windows/                   # Native Windows sources
├── stow-windows.ps1            # Existing Windows install-only entry point
├── scripts/                   # Direct utilities, including secret scanning
├── tests/                     # Profile, parser, and credential-loader checks
├── docs/                      # Bootstrap, validation, secrets, reference notes
│   └── archive/               # Superseded plans/configuration reports
├── .gitleaks.toml              # Detection rules and exact exemptions
└── .github/workflows/ci.yml    # Validation and secret-scanning jobs
```

## Package ownership

Paths inside a Stow package mirror paths relative to the target home directory.
For example, `packages/zsh/.config/zsh/.zshrc` becomes `~/.config/zsh/.zshrc`.

| Package | Managed targets |
| --- | --- |
| `core` | `~/.clang-format`, `~/.editorconfig` |
| `git` | Selected `~/.config/git/` config, ignores, attributes, hook, and local example |
| `zsh` | `~/.zshenv`, selected `~/.config/zsh/` files and examples |
| `fish` | Selected `~/.config/fish/` files, functions, and examples |
| `tmux` | `~/.tmux.conf`, `~/.local/bin/dotfiles-clipboard` |
| `vim` | `~/.vimrc`, `~/.vimrc_mac`, `~/.vimrc_linux`, shared `.vim/autoload/dotfiles.vim` |
| `nvim` | `~/.config/nvim/init.lua`, `lazy-lock.json`, `lua/dotfiles/clipboard.lua` |
| `vscode-macos` | `~/Library/Application Support/Code/User/` settings, keybindings, snippets |
| `alacritty` | `~/.config/alacritty/alacritty.toml` and its selected vendored theme |

`bin/dotfiles` uses `packages/` as Stow's package root and disables directory
folding, allowing local regular files to coexist with managed file links.
Package IDs are simple names such as `git`; there are no category-based installs.
Only selected packages are stowed. Root docs, scripts, profiles, and `windows/`
are outside this Stow root.

## Shared, host, and generated state

Shared preferences live in packages. Host settings live in regular `local.fish`,
`local.zsh`, and `config.local` files in the target home. Secret-store mappings
use `secrets.local.fish` and `secrets.local.zsh`; credentials belong in Keychain
or `pass`. These local files are not managed by Stow; their examples are.

Fish universal variables, `.DS_Store`, Python bytecode, and local validation
environments are generated state. `.gitignore` excludes known generated paths
and accidental package copies of local overrides. Git ignore rules do not
change Stow's behavior: do not place private local files inside a package even
if Git ignores them.

## Profiles and native Windows

`profiles/macos`, `profiles/linux`, and `profiles/wsl` select POSIX packages.
`all` uses OS detection; `@PROFILE` overrides it. `vscode-macos` appears only in
the macOS profile, so Linux/WSL installs create no `~/Library` paths.

`profiles/windows` selects logical groups from `windows/`, mapped to
`USERPROFILE`/`APPDATA` in `stow-windows.ps1`. This is a separate workflow;
status, dry-run, uninstall, and runtime validation are deferred.

Current instructions are in [README.md](README.md), [bootstrap](docs/bootstrap.md),
[validation](docs/validation.md), and [secret loading](docs/secrets.md).
[Archived reports](docs/archive/README.md) describe older layouts, not current commands.
