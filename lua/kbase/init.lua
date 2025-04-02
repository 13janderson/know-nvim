local M = {}

local P = function(tbl)
    local inspect = vim.inspect(tbl)
    print(inspect)
    return inspect
end

M.setup = function()
    print("Setup called")
end


-- [bufnum, lnum, col, off]
-- Not associative array but is indexed. Remember lua is 1 based indexing
-- "bufnum" is zero, unless a mark like '0 or 'A is used, then it
-- is the buffer number of the mark.
-- "lnum" and "col" are the position in the buffer.  The first
-- column is 1.
-- The "off" number is zero, unless 'virtualedit' is used.  Then
-- it is the offset in screen columns from the start of the
-- character.  E.g., a position within a <Tab> or after the last
-- character.

vim.keymap.set("v", "<leader>k", function()
    local cursor = vim.fn.getpos(".")
    local visualEnd= vim.fn.getpos("v")

    local mode = vim.fn.mode()
    -- lnum, col. If we are in visual mode then we don't care about what column we're in
    -- can use buf get lines or get text
    --
    -- It seems like the two positions are equal when we are just visually selecting a line

    local cursorLine, cursorCol, visualLine, visualCol = cursor[2], cursor[3], visualEnd[2], visualEnd[3]
    print(cursorLine, cursorCol, visualLine, visualCol)
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
        selection = vim.api.nvim_buf_get_text(0, selectionStartLine -1, selectionStartCol, selectionEndLine -1, selectionEndCol, false) 
    elseif mode == "V" then
        -- visual line mode
        selection = vim.api.nvim_buf_get_lines(0, selectionStartLine -1, selectionEndLine, false) 
    end
    P(selection)


    -- local selected = vim.api.nvim_buf_get_text(0, selectionStartLine-1, selectionStartCol-1, selectionEndLine-1, selectionEndCol-1, {})
    -- print(selectionStartLine, selectionStartCol, selectionEndLine, selectionEndCol)
    -- P(selected)

end)
return M
