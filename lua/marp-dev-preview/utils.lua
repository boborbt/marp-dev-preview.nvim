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

-- Recursively walk a tree-sitter node
local function traverse(node, fn)
  fn(node)
  for i = 0, node:child_count() - 1 do
    traverse(node:child(i), fn)
  end
end

-- Check if Tree-sitter supports this buffer
local function treesitter_available(bufnr)
  local ft = vim.bo[bufnr].filetype
  local ok = pcall(vim.treesitter.language.get_lang, ft)
  return ok
end

-- Check whether a row contains a non-comment, non-whitespace char
local function row_has_code(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

  if not line or line:match("^%s*$") then
    return false
  end

  -- If Tree-sitter is not available: skip analysis entirely
  if not treesitter_available(bufnr) then
    return true
  end

  -- Tree-sitter path
  local ft = vim.bo[bufnr].filetype
  local parser = vim.treesitter.get_parser(bufnr, ft)
  if not parser then
    return true  -- no parser → treat as having code
  end

  local tree = parser:parse()[1]
  if not tree then
    return true
  end

  local root = tree:root()

  -- Collect comment ranges on this row
  local comment_ranges = {}
  traverse(root, function(node)
    if node:type() == "comment" then
      local sr, sc, er, ec = node:range()
      if sr <= row and er >= row then
        table.insert(comment_ranges, { sc, ec })
      end
    end
  end)

  local function is_commented(col)
    for _, r in ipairs(comment_ranges) do
      if col >= r[1] and col < r[2] then
        return true
      end
    end
    return false
  end

  -- Check visible characters
  for col = 0, #line - 1 do
    local ch = line:sub(col + 1, col + 1)
    if ch:match("%S") and not is_commented(col) then
      return true
    end
  end

  return false
end

--- Find the first row at or after start_row containing code.
--- If Tree-sitter is not available, returns start_row immediately.
local function find_first_code_row(start_row, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- If TS unavailable: simplified behavior
  if not treesitter_available(bufnr) then
    return start_row
  end

  local last = vim.api.nvim_buf_line_count(bufnr) - 1
  for row = start_row, last do
    if row_has_code(bufnr, row) then
      return row
    end
  end

  return nil
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
