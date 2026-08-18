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


M.is_sep = function(buf, lnum)
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
  return line and line:match("^%s*%-%-%-%s*$") ~= nil
end


M.current_slide_number = function()
  local slide_number = -1
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  for line_no = 1, cur_line do
    --  if line.sub(line, 1, 3) == "---" then
    -- we cannot do as above, since we wanto to matcb
    -- only lines that have no other non blank character
    -- on the same line
    if M.is_sep(0, line_no) then
      slide_number = slide_number + 1
    end
  end
  return slide_number
end

M.num_slides = function()
  local slide_number = -1
  for line_no = 1, vim.api.nvim_buf_line_count(0) do
    if M.is_sep(0, line_no) then
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
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, -1, false)
  local current = start_line
  for _, line in ipairs(lines) do
    if M.is_sep(bufnr, current) then
      return start_line
    end

    local i = 1
    while i <= #line do
      if not in_comment then
        if line:sub(i, i + 3) == "<!--" then
          in_comment = true
          i = i + 4
        elseif line:sub(i, i) :match "%S" then
          return current
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

  return start_line
end

M.buf_goto_slide = function(slide_number)
  if not slide_number then
    return
  end

  local target_line = nil
  local current_slide = -1
  for lineno = 1, vim.api.nvim_buf_line_count(0) do
    if M.is_sep(0, lineno) then
      current_slide = current_slide + 1
      if current_slide == slide_number then
        target_line = lineno + 1
        break
      end
    end
  end

  if target_line then
    target_line = find_first_code_row(0, target_line)
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


M.prev_sep = function(buf, from)
  for lnum = from - 1, 1, -1 do
    if M.is_sep(buf, lnum) then
      return lnum
    end
  end
  return nil
end

M.next_sep = function(buf, from, last)
  for lnum = from + 1, last do
    if M.is_sep(buf, lnum) then
      return lnum
    end
  end
  return nil
end

local function is_box_open_line(line)
  return line and line:match("^%s*:::%s*%S") ~= nil
end

local function is_box_close_line(line)
  return line and line:match("^%s*:::%s*$") ~= nil
end

M.current_box_range = function(buf, cur)
  local stack = {}
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for lnum, line in ipairs(lines) do
    if is_box_open_line(line) then
      stack[#stack + 1] = lnum
    elseif is_box_close_line(line) then
      local start_lnum = stack[#stack]
      stack[#stack] = nil

      if start_lnum and cur >= start_lnum and cur <= lnum then
        return start_lnum, lnum
      end
    end
  end

  return nil, nil
end

M.next_box = function(buf, from, last)
  for lnum = from + 1, last do
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
    if is_box_open_line(line) then
      return lnum
    end
  end
  return nil
end

M.prev_box = function(buf, from)
  local current_start = M.current_box_range(buf, from)
  local search_from = current_start or from

  for lnum = search_from - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
    if is_box_open_line(line) then
      return lnum
    end
  end
  return nil
end

M.select_lines = function(start_lnum, end_lnum)
  if start_lnum > end_lnum then
    return
  end

  -- Reset an existing visual selection before creating ours. This must be
  -- synchronous; feedkeys() can leave the old visual anchor in place.
  if vim.fn.mode():match("[vV\022]") then
    vim.cmd("normal! \27")
  end

  vim.api.nvim_win_set_cursor(0, { start_lnum, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { end_lnum, 0 })
end


return M
