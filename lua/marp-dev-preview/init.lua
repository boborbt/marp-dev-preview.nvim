-- TODO:
-- [long term] Start the server from within Neovim if not running

local M = {}

local config = require("marp-dev-preview.config")
local state = require("marp-dev-preview.state")
local server = require("marp-dev-preview.server")
local autocommands = require("marp-dev-preview.autocommands")

M.config = {
  set = function(opt, val)
    config.options[opt] = val
  end,

  get = function(opt)
    return config.options[opt]
  end
}

-- exposed for testing
M._get_timers = function()
  return state.timers
end

-- exposed for testing
M._get_live_buffers = function()
  return state.live_buffers
end

M.setup = function(user_config)
  config.setup(user_config)
  autocommands.setup()
end

M.is_marp = function()
  if vim.bo.filetype ~= "markdown" then
    return false
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if state.buftypes[bufnr] ~= nil then
    return state.buftypes[bufnr]
  end

  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)) do
    if line:match "^[ \t]*marp[ \t]*:[ \t]*true[ \t]*$" then
      state.buftypes[bufnr] = true
      return true
    end
  end

  state.buftypes[bufnr] = false

  return false
end

M.current_slide_number = function()
  local slide_number = -1
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, cur_line, false)) do
    if line.sub(line, 1, 3) == "---" then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

M._goto_slide = function(slide_number)
  if not slide_number then
    return
  end

  local ok, response = server.server_cmd("goto", { key = "slide", value = slide_number })
  if not ok then
    vim.notify("Failed to go to slide: " .. response, vim.log.levels.ERROR)
    return
  end

  if response.status ~= 200 then
    vim.notify("Failed to go to slide: " .. response.body, vim.log.levels.ERROR)
  end
end

M.goto_slide = function()
  local input = vim.fn.input("Slide number: ")
  local slide_number = tonumber(input)

  if slide_number then
    M._goto_slide(slide_number)
    M.set_live_sync(false)
  else
    vim.notify(input .. " is not a valid number", vim.log.levels.INFO)
  end
end

M._last_slide_number = nil

M.goto_current_slide = function()
  local slide_number = M.current_slide_number()
  if slide_number ~= M._last_slide_number then
    M._last_slide_number = slide_number
    M._goto_slide(slide_number)
  end
end

M.find = function()
  local input = vim.fn.input("Search string: ")
  if input == "" then
    return
  end

  local ok, response = server.server_cmd("find", { key = "string", value = input })
  if not ok then
    vim.notify("Failed to search: " .. response, vim.log.levels.ERROR)
    return
  end

  if response.status == 200 then
    M.set_live_sync(false)
  else
    vim.notify("Failed to search: " .. response.body, vim.log.levels.ERROR)
  end
end

M.set_live_sync = function(val)
  if val and not M.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  state.live_buffers[bufnr] = val
end

M.toggle_live_sync = function()
  M.set_live_sync(not M.is_live_sync_on())

  if M.is_live_sync_on() then
    M.goto_current_slide()
  end
end

M.is_live_sync_on = function()
  local bufnr = vim.api.nvim_get_current_buf()
  return state.live_buffers[bufnr] == true
end

M.is_auto_save_on = function()
  local bufnr = vim.api.nvim_get_current_buf()
  return state.timers[bufnr] ~= nil
end

M._clear_timer = function(bufnr)
  state.timers[bufnr]:stop()
  state.timers[bufnr]:close()
  state.timers[bufnr] = nil
end

M.set_auto_save = function(val)
  if val == M.is_auto_save_on() then
    return
  end

  if val and not M.is_marp() then
    vim.notify("Refusing to start auto_save on non marp files")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if val then
    state.timers[bufnr] = vim.loop.new_timer()

    vim.notify("Started auto-save on buffer: " .. bufnr, vim.log.levels.INFO)
    state.timers[bufnr]:start(config.options.auto_save_interval, config.options.auto_save_interval,
      vim.schedule_wrap(function()
        if vim.bo.modified then
          vim.cmd("update")
        end
      end))
  else
    vim.notify("Stopping auto-save on buffer: " .. bufnr, vim.log.levels.INFO)
    M._clear_timer(bufnr)
  end
end

M.toggle_auto_save = function()
  M.set_auto_save(not M.is_auto_save_on())
end

return M
