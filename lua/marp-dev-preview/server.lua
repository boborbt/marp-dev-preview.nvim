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
  vim.notify("Check server returned: " .. tostring(chk),
    vim.log.levels.DEBUG,
    { title = "Marp Dev Preview" })

  return chk == "200"
end

-- Check if the server is running by sending a request to the given Port
-- Returns the HTTP status code if running, nil otherwise
-- @param port string The port to check, defaults to "8080" if not provided
-- @return string|nil The HTTP status code if the server is running, nil otherwise
function M.check_server(port)
  port = port or "8080"
  local url = string.format("http://localhost:%s", port)
  local cmd_str = string.format("curl -Is -o /dev/null -w '%%{http_code}' %s", url)

  local result = vim.fn.system(cmd_str)
  result = vim.trim(result)

  if result == "" then
    return nil
  end

  return result
end

function M.attach(port)
  if not port then
    vim.notify("Port not specified, cannot attach",
      vim.log.levels.ERROR,
      { title = "Marp Dev Preview" })
    return nil
  end

  vim.notify("Attaching to server at http://localhost:" .. port, vim.log.levels.DEBUG, { title = "Marp Dev Preview" })

  if not M.check_server(port) then
    vim.notify("No server running at the specified port",
      vim.log.levels.ERROR,
      { title = "Marp Dev Preview" })
    return nil
  end

  M.server_jobs[vim.api.nvim_buf_get_name(0)] = {
    port = port,
    shutdown = function() end,
    pid = nil
  }

  M.open_browser(port)

  return true
end

-- Stop the server associated with the current buffer or the given filename
-- If no filename is given, it defaults to the current buffer's filename
-- This function attempts to gracefully shut down the server process
-- If the process does not terminate, it forcefully kills it
-- It also removes the server job from the server_jobs table
-- to prevent memory leaks
-- @param filename string|nil The filename associated with the server to stop_all
-- If nil, uses the current buffer's filename
-- @return nil
function M.stop(filename)
  if not filename then
    filename = vim.api.nvim_buf_get_name(0)
  end

  local server_job = M.server_jobs[filename]
  M.server_jobs[filename] = nil

  if server_job == nil or server_job.pid == nil then
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

-- Stop all running server_jobs
-- This function iterates over all entries in the server_jobs table
-- and calls the stop function for each on_exit
-- It then clears the server_jobs table to free up memory
-- @return nil
function M.stop_all()
  for filename, _ in pairs(M.server_jobs) do
    M.stop(filename)
  end
  M.server_jobs = {}
end

-- Open the default web browser to the given Port
-- If no port is provided, it notifies the user of the ERROR
-- @param port string The port to open in the open_browser
-- @return nil
function M.open_browser(port)
  if not port then
    vim.notify("Port not specified, cannot open browser",
      vim.log.levels.ERROR,
      { title = "Marp Dev Preview" })
    return
  end
  vim.notify("Opening browser at http://localhost:" .. port,
    vim.log.levels.DEBUG,
    { title = "Marp Dev Preview" })
  vim.cmd("Open http://localhost:" .. port)
end

local function start_server_timer_callback(timer, filename, count, port)
  if M.server_jobs[filename] == nil then
    vim.notify("Server job no longer exists", vim.log.levels.WARN, { title = "Marp Dev Preview" })
    timer:stop()
    timer:close()
    return
  end
  count = count + 500
  if count > config.options.server_start_timeout then
    vim.notify("Server did not start in time, please check for errors", vim.log.levels.ERROR, { title = "Marp Dev Preview" })
    timer:stop()
    timer:close()
    return
  end

  if not port then
    vim.notify("Port not assigned yet, waiting...", vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
    return
  end

  if not M.check_server(port) then
    vim.notify("Server not responding yet, waiting...", vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
    return
  end

  M.open_browser(port)
  timer:stop()
  timer:close()
end

-- Start the marp server for the current buffer
-- @return nil
function M.start()
  if M.is_running() then
    vim.notify("Server is already running, bailing out",
      vim.log.levels.WARN,
      { title = "Marp Dev Preview" })
    return
  end
  -- Uses npx to start the marp server
  local Job = require("plenary.job")
  local theme_dir = config.options.theme_dir
  local filename = vim.api.nvim_buf_get_name(0)
  -- add some random number to the port to avoid conflicts
  local port = config.options.port + math.random(1, 1000)
  local server_args = { "marp-dev-preview", "--port", tostring(port) }
  if theme_dir then
    server_args:insert("--theme-dir")
    server_args:insert("filename")
  end

  local server_job = Job:new({
    command = "npx",
    args = server_args,
    on_stdout = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("[Marp] " .. data,
            vim.log.levels.DEBUG,
            { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.schedule(function()
          vim.notify("[Marp] " .. data,
            vim.log.levels.ERROR,
            { title = "Marp Dev Preview" })
        end)
      end
    end,
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        local result = table.concat(j:result(), "\n")
        vim.schedule(function()
          vim.notify("[Marp] Server exited with code " .. return_val .. "\n" .. result, vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
        end)
      else
        vim.schedule(function()
          vim.notify("[Marp] Server exited normally.", vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
        end)
      end

      M.server_jobs[filename] = nil
    end,
  })

  server_job.port = port
  server_job:start()

  M.server_jobs[filename] = server_job

  local timer = vim.loop.new_timer()
  local count = 0
  timer:start(500, 500, vim.schedule_wrap(function()
      start_server_timer_callback(timer, filename, count, port)
  end))

  vim.notify("Server started with pid: " .. server_job.pid, vim.log.levels.DEBUG, { title = "Marp Dev Preview" })
end

-- Send a command to the marp server associated with the current buffer
-- @param cmd string The command to send to the server
-- @param arg table A table containing a key and value to send with the command
-- Example
-- M.server_cmd("goto", { key = "slide", value = "4" })
-- @return boolean, table|nil A boolean indicating success, and the response table or nil
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

M.goto_slide = function(slide_number)
  if not slide_number then
    return true, nil
  end

  return M.server_cmd("goto", { key = "slide", value = slide_number })
end



-- Refresh the marp server with the given markdown Content-Type
-- @param markdown string The markdown content to send to the server_jobs
-- @return boolean, table|nil A boolean indicating success, and the response table or nil
function M.refresh(markdown)
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

    return curl.post("http://localhost:" .. port .. "/api/reload", {
      body = markdown,
      headers = { ["Content-Type"] = "text/markdown" },
      timeout = config.options.timeout,
    })
  end

  return pcall(call_curl)
end

return M
