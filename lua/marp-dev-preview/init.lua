local M = {}

M.compute_slide_number = function()
  local slide_number = 0
  for line in vim.api.nvim_buf_get_lines(0, 0, -1, false) do
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

M.goto = function()
  local input = vim.fn.input("Slide number: ")
  local slide_number = tonumber(input)
  if slide_number then
    local response = M.server_cmd("goto", { key = "slide", value = slide_number })
    if response.status == 200 then
      vim.notify("Went to slide " .. slide_number, vim.log.levels.INFO)
    else
      vim.notify("Failed to go to slide: " .. response.body, vim.log.levels.ERROR)
    end
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

return M
