-- TODO:
-- [long term] Start the server from within Neovim if not running

local M = {}

local config = require("marp-dev-preview.config")
local state = require("marp-dev-preview.state")
local server = require("marp-dev-preview.server")
local autocommands = require("marp-dev-preview.autocommands")
local utils = require("marp-dev-preview.utils")

-- Config options

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

M.start_server_and_live_sync = function()
  M.start_server()

  local count = 0

  timer = vim.loop.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    count = count + 500
    if count > config.options.live_sync_start_timeout then
      vim.notify("Server not started after ".. config.options.live_sync_start_timeout .. "ms, giving up",
        vim.log.levels.ERROR, { title = "Marp Dev Preview" })
      timer:stop()
      timer:close()
      return
    end

    server_live, status = server.is_running()
    if not server_live and status == "Check" then
      -- still starting up
      return
    end

    -- server is either running or failed to start
    timer:stop()
    timer:close()
  end))
end


M.goto_slide = function()
  local input = vim.fn.input("Slide number: ")
  local n = tonumber(input)
  local num_slides = utils.num_slides()

  if n and n >= 1 and n <= num_slides then
    utils.buf_goto_slide(n)
  else
    vim.notify(input .. " is not a valid slide number",
      vim.log.levels.ERROR, { title = "Marp Dev Preview" })
  end
end

M.next_slide = function()
  local n = utils.current_slide_number()
  if n < utils.num_slides() then
    n = n + 1
  end
  utils.buf_goto_slide(n)
end

M.prev_slide = function()
  local n = utils.current_slide_number()
  if n > 1 then
    n = n - 1
  end
  utils.buf_goto_slide(n)
end

M._last_slide_number = nil

M.goto_current_slide = function()
  local slide_number = utils.current_slide_number()
  if slide_number == M._last_slide_number then
    return true, nil
  end

  M._last_slide_number = slide_number
  return server.goto_slide(slide_number)
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

M.attach_to_server = function(port)
  if server.attach(port) then
    M.set_live_sync(true)
  end
end

M.set_live_sync = function(val)
  if val and not utils.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file",
      vim.log.levels.WARN, { title = "Marp Dev Preview" } )
    return false
  end

  vim.notify("Server is running: " .. tostring(server.is_running()),
    vim.log.levels.DEBUG, { title = "Marp Dev Preview" })

  if val and not server.is_running() then
    vim.notify("Server not found for buffer " .. vim.api.nvim_get_current_buf(),
      vim.log.levels.INFO, { title = "Marp Dev Preview" })
    return false
  end

  vim.notify("Live Sync " .. (val and "enabled" or "disabled"),
    vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
  local bufnr = vim.api.nvim_get_current_buf()
  state.live_buffers[bufnr] = val

  return true
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
    return " " .. "%#LiveSyncOn#󱚜%*"
  else
    return " " .. "%#LiveSyncOff#󱚜%*"
  end
end

return M
