-- always set leader first!
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "

-- Set terminal colors
vim.o.termguicolors = true

-------------------------------------------------------------------------------
--
-- preferences
--
-------------------------------------------------------------------------------
-- never ever folding
vim.opt.foldenable = false
vim.opt.foldmethod = 'manual'
vim.opt.foldlevelstart = 99
-- very basic "continue indent" mode (autoindent) is always on in neovim
-- could try smartindent/cindent, but meh.
-- vim.opt.cindent = true
-- XXX
-- vim.opt.cmdheight = 2
-- vim.opt.completeopt = 'menuone,noinsert,noselect'
-- not setting updatedtime because I use K to manually trigger hover effects
-- and lowering it also changes how frequently files are written to swap.
-- vim.opt.updatetime = 300
-- if key combos seem to be "lagging"
-- http://stackoverflow.com/questions/2158516/delay-before-o-opens-a-new-line
-- vim.opt.timeoutlen = 300
-- keep more context on screen while scrolling
vim.opt.scrolloff = 2
-- never show me line breaks if they're not there
vim.opt.wrap = false
-- always draw sign column. prevents buffer moving when adding/deleting sign
vim.opt.signcolumn = 'yes'
-- sweet sweet relative line numbers
vim.opt.relativenumber = true
-- and show the absolute line number for the current line
vim.opt.number = true
-- keep current content top + left when splitting
vim.opt.splitright = true
vim.opt.splitbelow = true
-- infinite undo!
-- NOTE: ends up in ~/.local/state/nvim/undo/
vim.opt.undofile = true
--" Decent wildmenu
-- in completion, when there is more than one match,
-- list all matches, and only complete to longest common match
vim.opt.wildmode = 'list:longest'
-- when opening a file with a command (like :e),
-- don't suggest files like there:
vim.opt.wildignore = '.hg,.svn,*~,*.png,*.jpg,*.gif,*.min.js,*.swp,*.o,vendor,dist,_site'

-- tabs: go big or go home: NO!
vim.opt.expandtab = false -- I am back tabs, use formatter do spaces for me
vim.opt.shiftwidth = 4    -- Number of spaces for an indent level
vim.opt.tabstop = 4       -- Number of spaces a \t character *looks like*
vim.opt.softtabstop = 4   -- Number of spaces Tab key inserts/deletes

-- case-insensitive search/replace
vim.opt.ignorecase = true
-- unless uppercase in search term
vim.opt.smartcase = true
-- never ever make my terminal beep
vim.opt.vb = true
-- more useful diffs (nvim -d)
--- by ignoring whitespace
vim.opt.diffopt:append('iwhite')
--- and using a smarter algorithm
--- https://vimways.org/2018/the-power-of-diff/
--- https://stackoverflow.com/questions/32365271/whats-the-difference-between-git-diff-patience-and-git-diff-histogram
--- https://luppeng.wordpress.com/2020/10/10/when-to-use-each-of-the-git-diff-algorithms/
vim.opt.diffopt:append('algorithm:histogram')
vim.opt.diffopt:append('indent-heuristic')
-- show a column at 80 characters as a guide for long lines
vim.opt.colorcolumn = '80'
--- except in Rust where the rule is 100 characters
local rust_formatting = vim.api.nvim_create_augroup('rust_formatting', { clear = true })
vim.api.nvim_create_autocmd('Filetype', {
    pattern = 'rust',
    group = rust_formatting,
    callback = function()
        vim.opt_local.colorcolumn = '100'
    end
})
-- show more hidden characters
-- also, show tabs nicer
vim.opt.list = true
vim.opt.listchars = 'tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•'
-- vim.opt.listchars = 'tab:  ,nbsp:¬,extends:»,precedes:«,trail:•'
-- vim.opt.listchars = 'tab:| ,nbsp:¬,extends:»,precedes:«,trail:•'

-- Use system clipboard in nvim
vim.opt.clipboard = "unnamed"

-------------------------------------------------------------------------------
--
-- hotkeys
--
-------------------------------------------------------------------------------
-- quick-open
vim.keymap.set('', '<C-p>', '<cmd>Files<cr>')
-- search buffers
vim.keymap.set('n', '<leader>;', '<cmd>Buffers<cr>', { desc = 'Search buffers' })
-- quick-save
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>', { desc = 'Quick save' })
-- make missing : less annoying
vim.keymap.set('n', ';', ':')
-- Ctrl+j and Ctrl+k as Esc (consolidated for all modes)
local escape_modes = { "n", "i", "v", "s", "x", "c", "o", "l", "t" }
local opts = { silent = true }
vim.keymap.set(escape_modes, '<C-j>', '<Esc>', opts)
-- Ctrl-j is a little awkward unfortunately:
-- https://github.com/neovim/neovim/issues/5916
-- So we also map Ctrl+k
vim.keymap.set(escape_modes, '<C-k>', '<Esc>', opts)
-- Ctrl+h to stop searching
vim.keymap.set('v', '<C-h>', '<cmd>nohlsearch<cr>')
vim.keymap.set('n', '<C-h>', '<cmd>nohlsearch<cr>')
-- Jump to start and end of line using the home row keys
vim.keymap.set('', 'H', '^')
vim.keymap.set('', 'L', '$')
-- Neat X clipboard integration
-- <leader>p will paste clipboard into buffer
-- <leader>c will copy entire buffer into clipboard
-- vim.keymap.set('n', '<leader>p', '<cmd>read !wl-paste<cr>', { desc = 'Paste from clipboard' })
-- vim.keymap.set('n', '<leader>c', '<cmd>w !wl-copy<cr><cr>', { desc = 'Copy buffer to clipboard' })
vim.keymap.set('n', '<leader>p', '<cmd>read !pbpaste<cr>', { desc = 'Paste from clipboard' })
vim.keymap.set('n', '<leader>c', '<cmd>w !pbcopy<cr><cr>', { desc = 'Copy buffer to clipboard' })
-- <leader><leader> toggles between buffers
vim.keymap.set('n', '<leader><leader>', '<c-^>', { desc = 'Toggle between buffers' })
-- <leader>, shows/hides hidden characters, this works with list chars
vim.keymap.set('n', '<leader>,', ':set invlist<cr>', { desc = 'Toggle hidden characters' })
-- Helper function for search centering
local function center_search(key)
	return key .. 'zz'
end

-- always center search results
local search_keys = { 'n', 'N', '*', '#', 'g*' }
for _, key in ipairs(search_keys) do
	vim.keymap.set('n', key, center_search(key), { silent = true })
end
-- "very magic" (less escaping needed) regexes by default
vim.keymap.set('n', '?', '?\\v')
vim.keymap.set('n', '/', '/\\v')
vim.keymap.set('c', '%s/', '%sm/')
-- open new file adjacent to current file
vim.keymap.set('n', '<leader>o', ':e <C-R>=expand("%:p:h") . "/" <cr>', { desc = 'Open file in current directory' })
-- no arrow keys --- force yourself to use the home row
vim.keymap.set('n', '<up>', '<nop>')
vim.keymap.set('n', '<down>', '<nop>')
vim.keymap.set('i', '<up>', '<nop>')
vim.keymap.set('i', '<down>', '<nop>')
vim.keymap.set('i', '<left>', '<nop>')
vim.keymap.set('i', '<right>', '<nop>')
-- let the left and right arrows be useful: they can switch buffers
vim.keymap.set('n', '<left>', ':bp<cr>')
vim.keymap.set('n', '<right>', ':bn<cr>')
-- make j and k move by visual line, not actual line, when text is soft-wrapped
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
-- handy keymap for replacing up to next _ (like in variable names)
vim.keymap.set('n', '<leader>m', 'ct_', { desc = 'Change to next underscore' })
-- F1 is pretty close to Esc, so you probably meant Esc
vim.keymap.set('', '<F1>', '<Esc>')
vim.keymap.set('i', '<F1>', '<Esc>')

-------------------------------------------------------------------------------
--
-- configuring diagnostics
--
-------------------------------------------------------------------------------
-- Allow virtual text
vim.diagnostic.config({ virtual_text = true, virtual_lines = false })


-------------------------------------------------------------------------------
--
-- autocommands
--
-------------------------------------------------------------------------------
-- highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({ timeout = 500 })
    end
})
-- jump to last edit position on opening file
vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*',
    callback = function(ev)
        if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
            -- except for in git commit messages
            -- https://stackoverflow.com/questions/31449496/vim-ignore-specifc-file-in-autocommand
            if not vim.fn.expand('%:p'):find('.git', 1, true) then
                vim.cmd('exe "normal! g\'\\""')
            end
        end
    end
})
-- prevent accidental writes to buffers that shouldn't be edited
local readonly_files = vim.api.nvim_create_augroup('readonly_files', { clear = true })
vim.api.nvim_create_autocmd('BufRead', {
    pattern = '*.orig',
    group = readonly_files,
    callback = function()
        vim.opt_local.readonly = true
    end
})
vim.api.nvim_create_autocmd('BufRead', {
    pattern = '*.pacnew',
    group = readonly_files,
    callback = function()
        vim.opt_local.readonly = true
    end
})
-- leave paste mode when leaving insert mode (if it was on)
local paste_mode = vim.api.nvim_create_augroup('paste_mode', { clear = true })
vim.api.nvim_create_autocmd('InsertLeave', {
    pattern = '*',
    group = paste_mode,
    callback = function()
        vim.opt.paste = false
    end
})
-- help filetype detection (add as needed)
--vim.api.nvim_create_autocmd('BufRead', { pattern = '*.ext', command = 'set filetype=someft' })
-- correctly classify mutt buffers
local email = vim.api.nvim_create_augroup('email', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
	pattern = '/tmp/mutt*',
	group = email,
	command = 'setfiletype mail',
})
-- also, produce "flowed text" wrapping
-- https://brianbuccola.com/line-breaks-in-mutt-and-vim/
vim.api.nvim_create_autocmd('Filetype', {
  pattern = 'mail',
  group = email,
  command = 'setlocal formatoptions+=w',
})
-- shorter columns in text because it reads better that way
local text = vim.api.nvim_create_augroup('text', { clear = true })
for _, pat in ipairs({'text', 'markdown', 'mail', 'gitcommit'}) do
	vim.api.nvim_create_autocmd('Filetype', {
		pattern = pat,
		group = text,
		command = 'setlocal spell tw=72 colorcolumn=73',
	})
end
--- tex has so much syntax that a little wider is ok
vim.api.nvim_create_autocmd('Filetype', {
	pattern = 'tex',
	group = text,
	command = 'setlocal spell tw=80 colorcolumn=81',
})
-- TODO: no autocomplete in text

-------------------------------------------------------------------------------
--
-- plugin configuration
--
-------------------------------------------------------------------------------
-- first, grab the manager
-- https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop -- compatibility with older Neovim versions
if not uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
-- then, setup!
require("lazy").setup({
	-- main color scheme
	{
		"wincent/base16-nvim",
		lazy = false, -- load at start
		priority = 1000, -- load first
		config = function()
			vim.cmd([[colorscheme gruvbox-dark-hard]])
			-- vim.cmd([[colorscheme base16-gruvbox-dark-hard]])
			vim.o.background = 'dark'
			-- XXX: hi Normal ctermbg=NONE
			--
			-- Make comments more prominent -- they are important.
			-- local bools = vim.api.nvim_get_hl(0, { name = 'Boolean' })
			-- vim.api.nvim_set_hl(0, 'Comment', bools)

			-- Make it clearly visible which argument we're at.
			local marked = vim.api.nvim_get_hl(0, { name = 'PMenu' })
			vim.api.nvim_set_hl(0, 'LspSignatureActiveParameter', { fg = marked.fg, bg = marked.bg, ctermfg = marked.ctermfg, ctermbg = marked.ctermbg, bold = true })
			-- XXX
			-- Would be nice to customize the highlighting of warnings and the like to make
			-- them less glaring. But alas
			-- https://github.com/nvim-lua/lsp_extensions.nvim/issues/21
			-- call Base16hi("CocHintSign", g:base16_gui03, "", g:base16_cterm03, "", "", "")
		end
	},
	-- nice bar at the bottom
	{
		'itchyny/lightline.vim',
		lazy = false, -- also load at start since it's UI
		config = function()
			-- no need to also show mode in cmd line when we have bar
			vim.o.showmode = false
			vim.g.lightline = {
				active = {
					left = {
						{ 'mode', 'paste' },
						{ 'readonly', 'filename', 'modified' }
					},
					right = {
						{ 'lineinfo' },
						{ 'percent' },
						{ 'fileencoding', 'filetype' }
					},
				},
				component_function = {
					filename = 'LightlineFilename'
				},
			}
			function LightlineFilenameInLua(opts)
				if vim.fn.expand('%:t') == '' then
					return '[No Name]'
				else
					return vim.fn.getreg('%')
				end
			end
			-- https://github.com/itchyny/lightline.vim/issues/657
			vim.api.nvim_exec(
				[[
				function! g:LightlineFilename()
					return v:lua.LightlineFilenameInLua()
				endfunction
				]],
				true
			)
		end
	},
	-- quick navigation
	{
		'ggandor/leap.nvim',
		event = "VeryLazy",
		config = function()
			require('leap').create_default_mappings()
		end
	},
	-- better %
	{
		'andymass/vim-matchup',
		event = "VeryLazy",
		config = function()
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end
	},
	-- auto-cd to root of git project
	{
		'notjedi/nvim-rooter.lua',
		event = "VeryLazy",
		config = function()
			require('nvim-rooter').setup()
		end
	},
	-- fzf support for ^p
	{
		'junegunn/fzf.vim',
		dependencies = {
			{ 'junegunn/fzf', dir = '~/.fzf', build = './install --all' },
		},
		config = function()
			-- stop putting a giant window over my editor
			vim.g.fzf_layout = { down = '~20%' }
			-- when using :Files, pass the file list through
			--
			--   https://github.com/jonhoo/proximity-sort
			--
			-- to prefer files closer to the current file.
			function list_cmd()
				local base = vim.fn.fnamemodify(vim.fn.expand('%'), ':h:.:S')
				if base == '.' then
					-- if there is no current file,
					-- proximity-sort can't do its thing
					return 'fd --hidden --type file --follow'
				else
					return vim.fn.printf('fd --hidden --type file --follow | proximity-sort %s', vim.fn.shellescape(vim.fn.expand('%')))
				end
			end
			vim.api.nvim_create_user_command('Files', function(arg)
				vim.fn['fzf#vim#files'](arg.qargs, { source = list_cmd(), options = '--scheme=path --tiebreak=index' }, arg.bang)
			end, { bang = true, nargs = '?', complete = "dir" })
		end
	},
	-- LSP
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			-- Setup mason
			require("mason").setup()
			require("mason-lspconfig").setup()

			-- Setup unified capabilities
			local capabilities = require('cmp_nvim_lsp').default_capabilities()

			-- Setup language servers
			local lspconfig = require('lspconfig')

			-- Define the servers to setup
			local servers = { "rust_analyzer", "clangd", "bashls", "ruff_lsp" }

			-- Setup each server with unified capabilities
			for _, server in ipairs(servers) do
				local server_config = {
					capabilities = capabilities,
				}

				-- Server-specific configurations
				if server == "clangd" then
					server_config.cmd = {
						"clangd",
						"--background-index",
						"--pch-storage=memory",
						"--clang-tidy",
					}
					server_config.filetypes = {"c", "cpp", "cc", "cuda", "ino"}
				elseif server == "rust_analyzer" then
					server_config.cmd = { vim.fn.expand("~/.cargo/bin/rust-analyzer") }
					server_config.settings = {
						["rust-analyzer"] = {
							cargo = {
								features = "all",
							},
							checkOnSave = {
								enable = true,
							},
							check = {
								command = "clippy",
							},
							imports = {
								group = {
									enable = false,
								},
							},
							completion = {
								postfix = {
									enable = false,
								},
							},
						},
					}
				elseif server == "bashls" then
					-- Only setup if bash-language-server is available
					if vim.fn.executable('bash-language-server') ~= 1 then
						goto continue
					end
				elseif server == "ruff_lsp" then
					-- Only setup if ruff-lsp is available
					if vim.fn.executable('ruff-lsp') ~= 1 then
						goto continue
					end
				end

				lspconfig[server].setup(server_config)
				::continue::
			end

			-- Global mappings.
			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open diagnostic float' })
			vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic' })
			vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic' })
			vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Set diagnostic loclist' })

			-- Use LspAttach autocommand to only map the following keys
			-- after the language server attaches to the current buffer
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					-- local opts = { buffer = ev.buf }
					vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc = 'Go to declaration' })
					vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Go to definition' })
					vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'Show hover info' })
					vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = ev.buf, desc = 'Go to implementation' })
					vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'Show signature help' })
					vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, { buffer = ev.buf, desc = 'Add workspace folder' })
					vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, { buffer = ev.buf, desc = 'Remove workspace folder' })
					vim.keymap.set('n', '<leader>wl', function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, { buffer = ev.buf, desc = 'List workspace folders' })
					--vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, { buffer = ev.buf, desc = 'Go to type definition' })
					vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, { buffer = ev.buf, desc = 'Rename symbol' })
					vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, { buffer = ev.buf, desc = 'Code action' })
					vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = ev.buf, desc = 'Go to references' })
					vim.keymap.set('n', '<leader>f', function()
						vim.lsp.buf.format { async = true }
					end, { buffer = ev.buf, desc = 'Format buffer' })

					local client = vim.lsp.get_client_by_id(ev.data.client_id)

					-- When https://neovim.io/doc/user/lsp.html#lsp-inlay_hint stabilizes
					-- TODO: find some way to make this only apply to the current line.
					if client.server_capabilities.inlayHintProvider then
					    vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
					end

					-- None of this semantics tokens business.
					-- https://www.reddit.com/r/neovim/comments/143efmd/is_it_possible_to_disable_treesitter_completely/
					client.server_capabilities.semanticTokensProvider = nil
				end,
			})
		end
	},
	-- LSP-based code-completion
	{
		"hrsh7th/nvim-cmp",
		-- load cmp on InsertEnter
		event = "InsertEnter",
		-- these dependencies will only be loaded when cmp loads
		-- dependencies are always lazy-loaded unless specified otherwise
		dependencies = {
			'neovim/nvim-lspconfig',
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require'cmp'
			cmp.setup({
				snippet = {
					-- REQUIRED by nvim-cmp. get rid of it once we can
					expand = function(args)
						vim.snippet.expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>'] = cmp.mapping.abort(),
					-- Accept currently selected item.
					-- Set `select` to `false` to only confirm explicitly selected items.
					['<CR>'] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
				}, {
					{ name = 'path' },
				}),
				experimental = {
					ghost_text = true,
				},
			})

			-- Enable completing paths in :
			cmp.setup.cmdline(':', {
				sources = cmp.config.sources({
					{ name = 'path' }
				})
			})
		end
	},
	-- inline function signatures
	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			-- Get signatures (and _only_ signatures) when in argument lists.
			require "lsp_signature".setup({
				doc_lines = 0,
				handler_opts = {
					border = "none"
				},
			})
		end
	},
	-- language support
	-- terraform
	{
		'hashivim/vim-terraform',
		ft = { "terraform" },
	},
	-- svelte
	{
		'evanleck/vim-svelte',
		ft = { "svelte" },
	},
	-- toml
	{
		'cespare/vim-toml',
		ft = { "toml" },
	},
	-- yaml
	{
		"cuducos/yaml.nvim",
		ft = { "yaml" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
	-- rust
	{
		'rust-lang/rust.vim',
		ft = { "rust" },
		config = function()
			vim.g.rustfmt_autosave = 1
			vim.g.rustfmt_emit_files = 1
			vim.g.rustfmt_fail_silently = 0
			vim.g.rust_clip_command = 'pbcopy'
		end
	},
	-- fish
	{
		'khaveesh/vim-fish-syntax',
		ft = { "fish" },
	},
	-- markdown
	{
		'plasticboy/vim-markdown',
		ft = { "markdown" },
		dependencies = {
			'godlygeek/tabular',
		},
		config = function()
			-- never ever fold!
			vim.g.vim_markdown_folding_disabled = 1
			-- support front-matter in .md files
			vim.g.vim_markdown_frontmatter = 1
			-- 'o' on a list item should insert at same level
			vim.g.vim_markdown_new_list_item_indent = 0
			-- don't add bullets when wrapping:
			-- https://github.com/preservim/vim-markdown/issues/232
			vim.g.vim_markdown_auto_insert_bullets = 0
		end
	},
})

--[[

leftover things from init.vim that i may still end up wanting

" Completion
" Better completion
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menuone,noinsert,noselect

" Settings needed for .lvimrc
set exrc
set secure

" Wrapping options
set formatoptions=tc " wrap text and comments using textwidth
set formatoptions+=r " continue comments when pressing ENTER in I mode
set formatoptions+=q " enable formatting of comments with gq
set formatoptions+=n " detect lists for formatting
set formatoptions+=b " auto-wrap in insert mode, and do not wrap old long lines

" <leader>s for Rg search
noremap <leader>s :Rg
let g:fzf_layout = { 'down': '~20%' }
command! -bang -nargs=* Rg
\ call fzf#vim#grep(
\   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
\   <bang>0 ? fzf#vim#with_preview('up:60%')
\           : fzf#vim#with_preview('right:50%:hidden', '?'),
\   <bang>0)

" <leader>q shows stats
nnoremap <leader>q g<c-g>

--]]
