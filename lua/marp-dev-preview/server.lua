local M = {
  server_jobs = {}
}

local config = require("marp-dev-preview.config")

function M.is_running()
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == nil or filename == "" then
    return false
  end

  local server_job = M.server_jobs[filename]

  if not server_job then
    return false
  end

  local chk = M.check_server(server_job.port)
  vim.notify("Check server returned: " .. tostring(chk), vim.log.levels.INFO)
  return chk == "200"
end

function M.check_server(port)
  port = port or "8080"
  local url = string.format("http://localhost:%s", port)

  local result = vim.fn.system(string.format("curl -Is -o /dev/null -w '%%{http_code}' %s", url))
  result = vim.trim(result)

  if result == "" then
    return nil
  end

  return result
end

function M.stop(filename)
  if not filename then
    filename = vim.api.nvim_buf_get_name(0)
  end

  local server_job = M.server_jobs[filename]

  if server_job == nil then
    return
  end

  -- this should close all pipes
  server_job:shutdown(0, 3)

  -- and since the process won't die
  local _handle = io.popen("kill " .. server_job.pid)
  if _handle ~= nil then
    _handle:close()
  end
end

function M.stop_all()
  for filename, _ in pairs(M.server_jobs) do
    M.stop(filename)
  end
  M.server_jobs = {}
end

function M.open_browser(port)
  if not port then
    vim.notify("Port not specified, cannot open browser", vim.log.levels.ERROR)
    return
  end
  vim.notify("Opening browser at http://localhost:" .. port, vim.log.levels.INFO)
  vim.cmd("Open http://localhost:" .. port)
end

function M.start()
  if M.is_running() then
    vim.notify("Server is already running, bailing out", vim.log.levels.WARN)
    return
  end
  -- Uses npx to start the marp server
  local Job = require("plenary.job")
  local theme_dir = config.options.theme_dir
  local filename = vim.api.nvim_buf_get_name(0)
  -- add some random to the port to avoid conflicts
  local port = config.options.port + math.random(1, 1000)

  if theme_dir == nil then
    theme_dir = '.'
  end

  local server_job = Job:new({
    command = "npx",
    args = { "marp-dev-preview", "--port", tostring(port), "--theme-dir", theme_dir, filename },
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("here1")
          vim.notify("[Marp] " .. data, vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("here2")
          vim.notify("[Marp] " .. data, vim.log.levels.ERROR, { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        local result = table.concat(j:result(), "\n")
        vim.schedule(function()
          vim.notify("here3")
          vim.notify("[Marp] Server exited with code " .. return_val .. "\n" .. result, vim.log.levels.ERROR,
            { title = "Marp Dev Preview" })
        end)
      else
        vim.schedule(function()
          vim.notify("here4")
          vim.notify("[Marp] Server exited normally.", vim.log.levels.INFO, { title = "Marp Dev Preview" })
        end)
      end
    end,
  })

  server_job.port = port
  server_job:start()

  M.server_jobs[filename] = server_job

  local timer = vim.loop.new_timer()
  timer:start(500, 500, vim.schedule_wrap(function()
    if not port then
      vim.notify("Port not assigned yet, waiting...", vim.log.levels.INFO)
      return
    end

    if not M.check_server(port) then
      vim.notify("Server not responding yet, waiting...", vim.log.levels.INFO)
      return
    end

    M.open_browser(port)
    timer:stop()
    timer:close()
  end))

  vim.notify("Server started with pid: " .. server_job.pid)
end

function M.server_cmd(cmd, arg)
  local curl = require("plenary.curl")
  local call_curl = function()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == nil or filename == "" then
      return nil, "No file associated with the current buffer"
    end
    local server_job = M.server_jobs[filename]
    if server_job == nil then
      return nil, "No server job found for the current file"
    end
    local port = server_job.port
    if port == nil then
      return nil, "No port found for the current server job, this is a bug. Please report it."
    end
    return curl.post("http://localhost:" .. port .. "/api/command", {
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
