state = require("marp-dev-preview.state")

local M = {}

M.is_marp = function()
  if vim.bo.filetype ~= "markdown" then
    return false
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if state.buftypes[bufnr] then
    return state.buftypes[bufnr]
  end

  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)) do
    if line:match "^%s*marp%s*:%s*true%s*$" then
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
    --  if line.sub(line, 1, 3) == "---" then
    -- we cannot do as above, since we wanto to matcb
    -- only lines that have no other non blank character
    -- on the same line
    if line:match "^%s*%-%-%-%s*$" then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

M.num_slides = function()
  local slide_number = -1
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:match "^%s*%-%-%-%s*$" then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

-- quick and dirty: finds the first char starting at start_line, 0
-- that is not contained in a comment. Stops at the next --- or
-- at the end of buffer
local function find_first_code_row(bufnr, start_line)
  local in_comment = false
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, -1, false)
  local current = start_line
  for _, line in ipairs(lines) do
    if line:match "^%s*%-%-%-%s*$" then
      return start_line
    end

    local i = 1
    while i <= #line do
      if not in_comment then
        if line:sub(i, i + 3) == "<!--" then
          in_comment = true
          i = i + 4
        elseif line:sub(i, i) :match "%S" then
          return current + 1
        else
          i = i + 1
        end
      else
        if line:sub(i, i + 2) == "-->" then
          in_comment = false
          i = i + 3
        else
          i = i + 1
        end
      end
    end
    current = current + 1
  end
end

M.buf_goto_slide = function(slide_number)
  if not slide_number then
    return
  end

  local target_line = nil
  local current_slide = -1
  for lineno, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:match "^%s*%-%-%-%s*$" then
      current_slide = current_slide + 1
      if current_slide == slide_number then
        target_line = lineno + 1
        break
      end
    end
  end

  if target_line then
    target_line = find_first_code_row(target_line - 1, 0) or target_line
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  else
    vim.notify("Slide number " .. slide_number .. " not found", vim.log.levels.ERROR)
  end
end

M.attempt_with_timeout = function(waittime, timeout, fn)
  local timer = vim.loop.new_timer()
  local stop = false
  timer:start(waittime, waittime, function()
    timeout = timeout - waittime
    stop = stop or timeout <= 0

    if stop then
      timer:stop()
      timer:close()
      return
    end

    vim.schedule(function()
      stop = stop or fn()
    end)
  end)
end

return M
