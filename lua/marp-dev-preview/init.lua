local M = {}
local H = {
  config = {
    live_sync = false
  }
}

M.setup = function(config)
  if not config then
    config = {}
  end

  -- updates default_config with user options
  for k,v in pairs(config) do H.config[k] = v end
end

M.current_slide_number = function()
  local slide_number = -1
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, cur_line, false)) do
    if line.sub(line,1,3)=="---" then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

M.server_cmd = function(cmd,arg)
  local curl = require("plenary.curl")
  local response = curl.post("http://localhost:8080/api/command", {
    body = vim.fn.json_encode({ command = cmd, [arg.key] = arg.value }),
    headers = { ["Content-Type"] = "application/json" },
  })
  return response
end

M._goto = function(slide_number)
  if slide_number then
    local response = M.server_cmd("goto", { key = "slide", value = slide_number })
    if response.status == 200 then
      vim.notify("Went to slide " .. slide_number, vim.log.levels.DEBUG)
    else
      vim.notify("Failed to go to slide: " .. response.body, vim.log.levels.ERROR)
    end
  end
end

M.goto = function()
  local input = vim.fn.input("Slide number: ")
  local slide_number = tonumber(input)
  M._goto(slide_number)
end

M._last_slide_number = nil

M.goto_current_slide = function()
  local slide_number = M.current_slide_number()
  if slide_number ~= M._last_slide_number then
    M._last_slide_number = slide_number
    M._goto(slide_number)
  end
end

M.find = function()
  local input = vim.fn.input("Search string: ")
  if input ~= "" then
    local response = M.server_cmd("find", { key = "string", value = input })
    if response.status == 200 then
      vim.notify("Searched for '" .. input .. "'", vim.log.levels.INFO)
    else
      vim.notify("Failed to search: " .. response.body, vim.log.levels.ERROR)
    end
  end
end


M.toggle_live_sync = function()
  H.config.live_sync = not H.config.live_sync
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
