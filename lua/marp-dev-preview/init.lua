-- TODO:
-- [long term] Start the server from within Neovim if not running

local M = {}

local config = require("marp-dev-preview.config")
local state = require("marp-dev-preview.state")
local server = require("marp-dev-preview.server")
local autocommands = require("marp-dev-preview.autocommands")

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

M.num_total_slides = function()
  local slide_number = -1
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line.sub(line, 1, 3) == "---" then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

M.buf_goto_slide = function(slide_number)
  if not slide_number then
    return
  end

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local target_line = nil
  local current_slide = -1
  for lineno, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line.sub(line, 1, 3) == "---" then
      current_slide = current_slide + 1
      if current_slide == slide_number then
        target_line = lineno + 1
        break
      end
    end
  end

  if target_line then
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  else
    vim.notify("Slide number " .. slide_number .. " not found", vim.log.levels.ERROR)
  end
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
  local num_slides = M.num_total_slides()

  if n and n >= 1 and n <= num_slides then
    M.buf_goto_slide(n)
    M._goto_slide(n)
  else
    vim.notify(input .. " is not a valid slide number", vim.log.levels.ERROR)
  end
end

M._last_slide_number = nil

M.goto_current_slide = function()
  local slide_number = M.current_slide_number()
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

M.set_live_sync = function(val)
  if val and not M.is_marp() then
    vim.notify("Refusing to start live sync on non-marp file", vim.log.levels.WARN)
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

return M
