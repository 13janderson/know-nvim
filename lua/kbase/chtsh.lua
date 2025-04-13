local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"
local conf = require("telescope.config").values
local Job = require("plenary.job")

local M = {}

-- Helper to print tables for debugging
local P = function(tbl)
  local inspect = vim.inspect(tbl)
  print(inspect)
  return inspect
end

-- Previewer that fetches sheet content with curl
local chtsh_previewer = previewers.new_termopen_previewer({
  get_command = function(entry)
    return { "curl", "-s", "cht.sh/" .. entry.value }
  end,
})

-- Main picker function
local chtsh = function(opts)
  opts = opts or {}

  -- Download the list of cheat topics (e.g. python/sort)
  Job:new({
    command = "curl",
    args = { "-s", "cht.sh/:list" },
    on_exit = function(j)
      local results = j:result()
      vim.schedule(function()
        pickers.new(opts, {
          prompt_title = "cht.sh",
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
          previewer = chtsh_previewer,
          sorter = conf.generic_sorter(opts),
        }):find()
      end)
    end,
  }):start()
end

-- Optional keybinding setup
M.setup = function()
  vim.keymap.set("n", "<leader>sk", chtsh, { desc = "Search cht.sh" })
end

-- Uncomment to auto-run picker on load
chtsh()

return M

