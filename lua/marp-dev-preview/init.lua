-- TODO:
-- [long term] Start the server from within Neovim if not running

local M = {}

local config = require("marp-dev-preview.config")
local state = require("marp-dev-preview.state")
local server = require("marp-dev-preview.server")
local autocommands = require("marp-dev-preview.autocommands")
local utils = require("marp-dev-preview.utils")

M.get = function(opt)
  return config.options[opt]
end

M.set = function(opt, value)
  config.options[opt] = value
end

-- exposed for testing
M._get_live_buffers = function()
  return state.live_buffers
end

M.setup = function(user_config)
  config.setup(user_config)
  autocommands.setup()
end

M._goto_slide = function(slide_number)
  if not slide_number then
    return true, nil
  end

  return server.server_cmd("goto", { key = "slide", value = slide_number })
end

M.goto_slide = function()
  local input = vim.fn.input("Slide number: ")
  local n = tonumber(input)
  local num_slides = utils.num_slides()

  if n and n >= 1 and n <= num_slides then
    utils.buf_goto_slide(n)
    M._goto_slide(n)
  else
    vim.notify(input .. " is not a valid slide number", vim.log.levels.ERROR)
  end
end

M._last_slide_number = nil

M.goto_current_slide = function()
  local slide_number = utils.current_slide_number()
  if slide_number == M._last_slide_number then
    return true, nil
  end

  M._last_slide_number = slide_number
  return M._goto_slide(slide_number)
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

M.start_server = function()
  server.start()
end

M.stop_server = function()
  -- sotp all live synced live_buffers
  for bufnr, _ in pairs(state.live_buffers) do
    state.live_buffers[bufnr] = false
  end
  server.stop()
end

M.set_live_sync = function(val)
  if val and not utils.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file",
      vim.log.levels.WARN)
    return
  end

  vim.notify("Server is running: " .. tostring(server.is_running()), vim.log.levels.INFO)

  if val and not server.is_running() then
    vim.notify("Server not found for buffer " .. vim.api.nvim_get_current_buf(),
      vim.log.levels.INFO)
    return
  end

  vim.notify("Live sync " .. (val and "enabled" or "disabled"), vim.log.levels.INFO)
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

-- lualine status line component
-- returns a symbol showing:
-- - nothing if not a marp file
-- - 'Marp" if marp file but live sync Off"'

M.statusline = function()
  if not utils.is_marp() then
    return ""
  end

  if M.is_live_sync_on() then
    return "Marp: %#DiffAdd#🔄%*"
  else
    return "Marp: %#DiffDelete#🔄%*"
  end
end

return M
