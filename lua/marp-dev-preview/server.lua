local M = {}

local config = require("marp-dev-preview.config")

function M.server_cmd(cmd, arg)
  local curl = require("plenary.curl")
  local call_curl = function()
    return curl.post("http://localhost:" .. config.options.port .. "/api/command", {
      body = vim.fn.json_encode({ command = cmd, [arg.key] = arg.value }),
      headers = { ["Content-Type"] = "application/json" },
      timeout = config.options.timeout,
    })
  end

  local ok, response = pcall(call_curl)

  return ok, response
end

function M.refresh(markdown)
  local curl = require("plenary.curl")
  local call_curl = function()
    return curl.post("http://localhost:" .. config.options.port .. "/api/reload", {
      body = markdown,
      headers = { ["Content-Type"] = "text/markdown" },
      timeout = config.options.timeout,
    })
  end

  return pcall(call_curl)
end

return M
