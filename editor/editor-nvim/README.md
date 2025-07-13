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

### Recent Optimizations (2025-07-13)
- **Fixed Rust clipboard command**: Changed from `wl-copy` to `pbcopy` for macOS compatibility
- **Fixed LSP inlay hints bug**: Corrected undefined `bufnr` variable to `ev.buf`
- **Simplified LSP keymaps**: Removed unnecessary helper function for cleaner, more standard code
- **Updated deprecated vim.loop**: Changed to `vim.uv or vim.loop` for newer Neovim compatibility
- **Improved plugin lazy loading**: Added `event = "VeryLazy"` to leap.nvim, vim-matchup, and nvim-rooter for faster startup
- **Performance impact**: Plugins now load "just in time" rather than all at startup, improving initial responsiveness

