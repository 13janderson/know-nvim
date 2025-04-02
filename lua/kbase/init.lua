local M = {}

local P = function(tbl)
    local inspect = vim.inspect(tbl)
    print(inspect)
    return inspect
end

M.setup = function()
    print("Setup called")
end

vim.keymap.set("v", "<leader>k", function()
    local cursor = vim.fn.getpos(".")
    local visualEnd= vim.fn.getpos("v")

    local mode = vim.fn.mode()
    -- lnum, col. If we are in visual mode then we don't care about what column we're in
    -- can use buf get lines or get text
    --
    -- It seems like the two positions are equal when we are just visually selecting a line

    local cursorLine, cursorCol, visualLine, visualCol = cursor[2], cursor[3], visualEnd[2], visualEnd[3]
    local selectionStartLine, selectionEndLine, selectionStartCol, selectionEndCol =
        cursorLine, visualLine, cursorCol, visualCol
    if  cursorLine == visualLine and cursorCol == visualCol then
        -- Single line selection which is covered by above default
    else
        -- We want to determine where to start the selection by picking the largest of the two cursors
        if cursorLine > visualLine then
            selectionStartLine = visualLine
            selectionEndLine = cursorLine
            selectionStartCol = visualCol
            selectionEndCol = cursorCol
        end
    end

    local selection
    -- We want different bevhaiour depending on whether we are in visual line mode or visual mode 
    -- Visual line mode, we simply want to select the lines
    if mode == "v" then
        -- visual mode
        selection = vim.api.nvim_buf_get_text(0, selectionStartLine -1, selectionStartCol, selectionEndLine -1, selectionEndCol, {})
    elseif mode == "V" then
        -- visual line mode
        selection = vim.api.nvim_buf_get_lines(0, selectionStartLine -1, selectionEndLine, false) 
    end
    local selectedLines = table.concat(selection, "\n")

    print(selectedLines)
    local fileType = vim.filetype
    local tag = vim.fn.input("%s tag:", fileType)
    -- Go back to normal mode, replacing termcodes like <C-c> with their internal representation rather than 
    -- feeding these exact keys
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-c>', true, false, true), 'n', true)
end)
return M
