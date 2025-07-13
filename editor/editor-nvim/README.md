# Neovim Configuration

### Directory Layout
```
.editor-nvim/
├── .config/
│   └── nvim/
│       ├── init.lua          # Main configuration file
│       └── lua/             # Custom Lua scripts can be placed here
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
- `Esc`: Remapped to `Ctrl + j` and `Ctrl + k` in all modes.
- `Ctrl + h`: Stops searching (highlights).
- `Leader + o`: Open new file adjacent to current.
- `Leader + ,`: Toggle hidden characters.

### Additional Features
- **LSP Support**: Multi-language support with auto-configuration.
- **Diagnostics**: Integrated diagnostics with virtual text.
- **Miscellaneous**: Clipboards integration and enhanced navigation.

