# Neovim Configuration

### Directory Layout
```
packages/nvim/
├── .config/
│   └── nvim/
│       ├── init.lua          # Main configuration file
│       ├── lazy-lock.json    # Plugin lockfile
│       └── lua/dotfiles/clipboard.lua # Native clipboard-provider mappings
```

### Plugin Installation
- **Plugin Manager:** This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) to manage plugins.
- **Installation:**
  1. Ensure `git` is installed as it’s required for cloning.
  2. `lazy.nvim` is automatically installed in `nvim` data directory if not found.

### Common Keybindings
- `Space`: Leader key.
- `Ctrl + p`: Open files using FZF.
- `Leader + ;`: Search buffers.
- `Leader + w`: Quick save.
- `Ctrl + j` / `Ctrl + k`: Act as Escape; an attached LSP can override normal-mode `Ctrl + k` for signature help.
- `Ctrl + h`: Stops searching (highlights).
- `Leader + o`: Open new file adjacent to current.
- `Leader + ,`: Toggle hidden characters.

### Additional Features
- **LSP Support**: Multi-language support with auto-configuration.
- **Diagnostics**: Integrated diagnostics with virtual text.
- **Miscellaneous**: Clipboards integration and enhanced navigation.

### Setup and validation

Install using `./bin/dotfiles install nvim` from the repository root. First
launch can download lazy.nvim and plugins; installing links does not install
language servers, external tools, or clipboard utilities.

The clipboard mappings use Neovim's native `+` register/provider. macOS,
Wayland, X11, and user-supplied providers can be selected by Neovim; install
the tools required by your graphical session. `Leader + c` copies the whole
buffer, and `Leader + p` inserts clipboard lines after the current line. An
empty clipboard or missing provider leaves the buffer unchanged; a missing
provider produces a warning. See [bootstrap dependencies](../../docs/bootstrap.md#application-dependencies-and-limitations).
The [format validator](../../docs/validation.md#configuration-formats) compiles
`init.lua` without executing its plugin bootstrap. Passing that check does not
verify plugin or language-server runtime behavior.

