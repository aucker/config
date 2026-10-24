local M = {}

local function available()
    if vim.fn.has('clipboard') == 1 then
        return true
    end
    vim.notify('No system clipboard provider is available', vim.log.levels.WARN)
    return false
end

function M.copy_buffer()
    if not available() then
        return false
    end
    vim.fn.setreg('+', vim.api.nvim_buf_get_lines(0, 0, -1, false), 'V')
    return true
end

function M.paste_after_line()
    if not available() then
        return false
    end
    local lines = vim.fn.getreg('+', 1, true)
    if #lines > 0 and not (#lines == 1 and lines[1] == '') then
        vim.api.nvim_put(lines, 'l', true, true)
    end
    return true
end

return M
