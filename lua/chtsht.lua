local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Job = require("plenary.job")

local M = {}

Cache = {}

-- Cache class
function Cache:new()
    local cachePath = string.format("%s/%s/%s", os.getenv("HOME"), ".cache", "chtsht")
    vim.fn.mkdir(cachePath, "p")
    local newCache = {cachePath = cachePath}
    self.__index = self
    return setmetatable(newCache, self)
end

function Cache:read(path)
    -- return the data of in the file or nil if no cache entry
    local cachePath = self:cachedFilePath(path)
    local cacheFile = io.open(cachePath, "r")
    local fileLines = {}
    for line in cacheFile:lines() do
        table.insert(fileLines, line)
    end
    return fileLines
end


function Cache:write(path, data)
    local cacheFile = io.open(self:cachedFilePath(path), "a")
    for _, value in pairs(data) do
        cacheFile:write(string.format("%s\n", value))
    end
    cacheFile:close()

end

function Cache:cachedFilePath(path)
    local ret = string.format("%s/%s", self.cachePath, vim.fn.sha256(path))
    return ret
end


local function open_sheet(path)
    vim.cmd("vnew")
    vim.cmd("setlocal buftype=nofile bufhidden=hide noswapfile")
    local lang = vim.split(path, "/")[1]
    if lang then
        vim.api.nvim_buf_set_option(0, "filetype", lang) -- Set filetype
    end
    local cache = Cache:new()
    local cacheRead = cache:read(path)
    -- check for file in cache - need a better naming scheme for files - can just cache the path to not have to worry
    if cacheRead then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, cacheRead)
    else
        local cmd = string.format("curl -s 'cht.sh/%s' | sed $'s/\\x1b\\[[0-9;]*m//g'", path)
        local jobid = vim.fn.jobstart(cmd, {
            stdout_buffered = true,
            on_stdout = function(_, data)
                if data then
                    -- Save data to cache
                    cache:write(path, data)
                    vim.api.nvim_buf_set_lines(0, 0, -1, false, data)
                end
            end,
        })
    end
end


-- Main recursive picker
local function pick_list(path, opts)
    opts = opts or {}
    local full_path = path or ""

    local url = full_path == "" and "cht.sh/:list" or ("cht.sh/" .. full_path .. ":list")

    Job:new({
        command = "curl",
        args = { "-s", url },
        on_exit = function(j)
            local results = j:result()

            vim.schedule(function()
                pickers.new(opts, {
                    prompt_title = full_path == "" and "cht.sh" or full_path,
                    finder = finders.new_table {
                        results = results,
                        entry_maker = function(line)
                            return {
                                value = line,
                                display = line,
                                ordinal = line,
                            }
                        end,
                    },
                    previewer = previewers.new_termopen_previewer({
                        get_command = function(entry)
                            return { "curl", "-s", "cht.sh/" .. full_path .. entry.value }
                        end,
                    }),
                    sorter = conf.generic_sorter(opts),
                    attach_mappings = function(prompt_bufnr, map)
                        map("i", "<CR>", function()
                            local entry = action_state.get_selected_entry()
                            actions.close(prompt_bufnr)

                            local selected = entry.value
                            if selected:sub(-1) == "/" then
                                -- Recurse into directory
                                pick_list(full_path .. selected, opts)
                            else
                                -- Open the final sheet
                                open_sheet(full_path .. selected)
                            end
                        end)
                        return true
                    end,
                }):find()
            end)
        end,
    }):start()
end

-- Optional setup function for keybinding
M.setup = function()
    vim.keymap.set("n", "<leader>sc",  function()
        pick_list("")
    end, { desc = "Search cht.sh" })
end


return M

