-- TODO:
-- to be handled correctly the auto_save option:
--  - if it is on, then for every new marp file opened, call toggle_auto_save to turn
--    the timer on. mmm... there can be at most one file opened (the server is listening
--    on the fixed port configured here)
--    - should have been fixed... the plugin will monitor file changes and, if auto_save
--      is true will start the autosaving on markdown files.
--  - if it is off, leave to the user turning it on
-- [longterm] Start the server from within Neovim if not running

local M = {}
local H = {
  config = {
    -- marp-dev-preview server port
    port = 8080,
    -- marp-dev-preview server connection_timeout
    timeout=1000,

    live_sync = false,
    auto_save = false,
    --- autosave every second if file
    --- has been changed
    auto_save_debounce = 1000
  },

  -- we need to activate timers bufferwise,
  -- otherwise we may start it on one buffer
  -- and start saving on another one
  timers = {},

  -- same thing with live_sync, here it
  -- simpler because we don't have timers
  live_buffers = {}
}

M.config = {
  set = function(opt, val)
    H.config[opt] = val
  end,

  get = function(opt)
    return H.config[opt]
  end
}

M.setup = function(config)

  if not config then
    config = {}
  end

  -- updates default_config with user options
  for k, v in pairs(config) do H.config[k] = v end
end

M.is_marp = function()
  if vim.bo.filetype ~= "markdown" then
    return false
  end

  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 20, false)) do
    if line:match "^[ \t]*marp[ \t]*:[ \t]*true[ \t]*$" then
      return true
    end
  end

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

M.server_cmd = function(cmd, arg)
  vim.notify("connecting to port "..H.config.port)

  local curl = require("plenary.curl")
  local call_curl = function()
    return curl.post("http://localhost:"..H.config.port.."/api/command", {
      body = vim.fn.json_encode({ command = cmd, [arg.key] = arg.value }),
      headers = { ["Content-Type"] = "application/json" },
      timeout = H.config.timeout,
    })
  end

  local ok, response = pcall(call_curl)

  return ok, response
end

M._goto_slide = function(slide_number)
  if slide_number then
    local ok, response = M.server_cmd("goto", { key = "slide", value = slide_number })
    if ok and response.status == 200 then
      vim.notify("Went to slide " .. slide_number, vim.log.levels.DEBUG)
    else
      vim.notify("Failed to go to slide: " .. response.body, vim.log.levels.ERROR)
    end
  end
end

M.goto_slide = function()
  local input = vim.fn.input("Slide number: ")
  local slide_number = tonumber(input)

  -- this is a little repetitive, but avoids turnig off setting live sync
  -- if the slide_number is not valid
  if slide_number then
    M._goto_slide(slide_number)
    M.set_live_sync(false)
  else
    vim.notify(input .. " is not a valid number", vim.log.levels.DEBUG)
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
  if input ~= "" then
    local ok, response = M.server_cmd("find", { key = "string", value = input })
    if ok and response.status == 200 then
      vim.notify("Searched for '" .. input .. "'", vim.log.levels.INFO)
      M.set_live_sync(false)
    else
      vim.notify("Failed to search: " .. response.body, vim.log.levels.ERROR)
    end
  end
end

M.set_live_sync = function(val)
  if val and not M.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file")
  end


  local bufnr = vim.api.nvim_get_current_buf()

  H.live_buffers[bufnr] = val
end

-- Toggle live sync for the current file. This does not activate/deactivate
-- config.live_sync (which can be done calling M.config.set('live_sync', true/false)
M.toggle_live_sync = function()
  if not M.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file")
  end


  M.set_live_sync(not M.is_live_sync_on())

  if M.is_live_sync_on() then
    M.goto_current_slide()
  end
end

M.is_live_sync_on = function()
  local bufnr = vim.api.nvim_get_current_buf()
  return H.live_buffers[bufnr]
end

M.auto_save_is_on = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if H.timers[bufnr] == nil then  -- the timer was not running
    return false
  else
    return true
  end
end

M._get_timers = function()
  return H.timers
end

M._clear_timer = function(bufnr)
  H.timers[bufnr]:stop()
  H.timers[bufnr]:close()
  H.timers[bufnr] = nil
end

-- Toggle auto save for the current file. This does not activate/deactivate
-- config.auto_save (which can be done by calling M.config.set('auto_save', true/false)
M.toggle_auto_save = function()
  -- bail out if the file type is not markdown
  if not M.is_marp() then
    vim.notify("MDP: refusing to start auto_save on non marp files")
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if not M.auto_save_is_on() then
    -- start auto_save
    H.timers[bufnr] = vim.loop.new_timer()

    vim.notify("Started auto-save on buffer: "..bufnr, vim.log.levels.INFO)
    H.timers[bufnr]:start(H.config.auto_save_debounce, H.config.auto_save_debounce, vim.schedule_wrap(function()
      if vim.bo.modified then
        vim.cmd("update")  -- save if modified and markdown
      end
    end))
  else
    -- stop auto_save
    vim.notify("Stopping auto-save on buffer: "..bufnr, vim.log.levels.INFO)

    M._clear_timer(bufnr)
  end
end

vim.api.nvim_create_augroup("MarpDevPreview", { clear = true })

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  group = "MarpDevPreview",
  pattern = "*.md",
  callback = function()
    if H.config.auto_save then
      M.toggle_auto_save()
    end

    M.set_live_sync(H.config.live_sync)
  end
})

vim.api.nvim_create_autocmd({"BufUnload", "BufWipeout"}, {
  group = "MarpDevPreview",
  pattern = "*.md",
  callback = function(args)
    if H.timers[args.buf] then
      M._clear_timer(args.buf)
    end
  end
})

vim.api.nvim_create_autocmd("CursorMoved", {
  group = "MarpDevPreview",
  pattern = "*.md",
  callback = function()
    if M.is_live_sync_on() then
      M.goto_current_slide()
    end
  end
})

return M
