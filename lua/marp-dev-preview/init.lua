-- TODO:
-- 1. make goto and find to switch off auto_sync
-- 2. make "toggling auto_sync to true" to call goto_current_slide


local M = {}
local H = {
  config = {
    live_sync = false,
    auto_save = false,
    --- autosave every second if file
    --- has been changed
    auto_save_debounce = 1000
  },

  -- we need to activate timers bufferwise,
  -- otherwise we may start it on one buffer
  -- and start saving on another one
  timers = {}
}

M.setup = function(config)
  if not config then
    config = {}
  end

  -- updates default_config with user options
  for k, v in pairs(config) do H.config[k] = v end
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
  local curl = require("plenary.curl")
  local response = curl.post("http://localhost:8080/api/command", {
    body = vim.fn.json_encode({ command = cmd, [arg.key] = arg.value }),
    headers = { ["Content-Type"] = "application/json" },
  })
  return response
end

M._goto_slide = function(slide_number)
  if slide_number then
    local response = M.server_cmd("goto", { key = "slide", value = slide_number })
    if response.status == 200 then
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
    H.config.live_sync = false
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
    local response = M.server_cmd("find", { key = "string", value = input })
    if response.status == 200 then
      vim.notify("Searched for '" .. input .. "'", vim.log.levels.INFO)
      H.config.live_sync = false
    else
      vim.notify("Failed to search: " .. response.body, vim.log.levels.ERROR)
    end
  end
end


M.toggle_live_sync = function()
  H.config.live_sync = not H.config.live_sync
  if H.config.live_sync then
    M.goto_current_slide()
  end
end

M.toggle_auto_save = function()
  -- bail out if the file type is not markdown
  if vim.bo.filetype ~= "markdown" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if H.timers[bufnr] == nil then  -- the timer was not running
    H.timers[bufnr] = vim.loop.new_timer()

    vim.notify("Started auto-save on buffer: "..bufnr)

    H.timers[bufnr]:start(1000, 1000, vim.schedule_wrap(function()
      if vim.bo.modified then
        vim.cmd("update")  -- save if modified and markdown
      end
    end))
  else
    vim.notify("Stopping auto-save on buffer: "..bufnr)

    H.timers[bufnr]:stop()
    H.timers[bufnr]:close()
    H.timers[bufnr] = nil
  end
end

vim.api.nvim_create_augroup("SlideSync", { clear = true })

vim.api.nvim_create_autocmd("CursorMoved", {
  group = "SlideSync",
  pattern = "*.md",
  callback = function()
    if H.config.live_sync then
      M.goto_current_slide()
    end
  end
})

return M
