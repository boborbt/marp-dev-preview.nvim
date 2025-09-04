local M = {
  server_job = nil
}

local config = require("marp-dev-preview.config")

function M.is_running()
  return M.server_job ~= nil
end

function M.stop()
  if not M.is_running() then
    return
  end
  -- this should close all pipes
  M.server_job:shutdown(0, 3)


  -- and since the process won't die
  local _handle = io.popen("kill " .. M.server_job.pid)
  if _handle ~= nil then
    _handle:close()
  end
end

function M.open_browser()
  if M.server_job == nil then
    return
  end

  vim.cmd("Open http://localhost:" .. config.options.port)
end

function M.start()
  -- Uses npx to start the marp server
  local Job = require("plenary.job")
  local theme_dir = config.options.theme_dir
  local filename = vim.api.nvim_buf_get_name(0)

  if theme_dir == nil then
    theme_dir = '.'
  end

  M.server_job = Job:new({
    command = "npx",
    args = { "marp-dev-preview", "--port", tostring(config.options.port), "--theme-dir", theme_dir, filename },
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("[Marp] " .. data, vim.log.levels.INFO, { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("[Marp] " .. data, vim.log.levels.ERROR, { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        local result = table.concat(j:result(), "\n")
        vim.schedule(function()
          vim.notify("[Marp] Server exited with code " .. return_val .. "\n" .. result, vim.log.levels.ERROR,
            { title = "Marp Dev Preview" })
        end)
      else
        vim.schedule(function()
          vim.notify("[Marp] Server exited normally.", vim.log.levels.INFO, { title = "Marp Dev Preview" })
        end)
      end
    end,
  })

  M.server_job:start()

  local timer = vim.loop.new_timer()
  timer:start(2000, 0, vim.schedule_wrap(M.open_browser))

  vim.notify("Server started with pid: " .. M.server_job.pid)
end

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
