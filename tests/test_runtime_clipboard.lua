-- Run without init.lua/plugins and without touching a desktop clipboard.
local store = { lines = {}, regtype = 'v' }
local function copy(lines, regtype)
    store.lines = vim.deepcopy(lines)
    store.regtype = regtype
end
local function paste()
    return { vim.deepcopy(store.lines), store.regtype }
end
vim.g.clipboard = {
    name = 'offline fixture',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
    cache_enabled = 0,
}
local clipboard = dofile(vim.env.DOTFILES_TEST_REPO .. '/packages/nvim/.config/nvim/lua/dotfiles/clipboard.lua')
assert(vim.fn.has('clipboard') == 1, 'fixture provider was not registered')

vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'alpha', 'βeta' })
assert(clipboard.copy_buffer())
assert(table.concat(store.lines, '\n') == 'alpha\nβeta\n',
    'copy did not preserve buffer text and the final newline: ' .. vim.inspect(store.lines))
assert(store.regtype == 'V', 'whole-buffer copy must be linewise')

vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'before', 'after' })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
store.lines = { 'first', 'second' }
store.regtype = 'v'
assert(clipboard.paste_after_line())
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { 'before', 'first', 'second', 'after' }),
    'paste did not insert after the current line')

store.lines = {}
local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(clipboard.paste_after_line())
assert(vim.deep_equal(before, vim.api.nvim_buf_get_lines(0, 0, -1, false)), 'empty clipboard changed the buffer')

local original_has, original_notify = vim.fn.has, vim.notify
local warnings = 0
vim.fn.has = function() return 0 end
vim.notify = function() warnings = warnings + 1 end
assert(not clipboard.copy_buffer())
assert(not clipboard.paste_after_line())
assert(warnings == 2, 'missing provider did not produce a clear warning')
assert(vim.deep_equal(before, vim.api.nvim_buf_get_lines(0, 0, -1, false)), 'missing provider changed the buffer')
vim.fn.has, vim.notify = original_has, original_notify
