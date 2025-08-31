local M = {}

M.options = {
  -- marp-dev-preview server port
  port = 8080,
  -- marp-dev-preview server connection_timeout
  timeout = 1000,

  live_sync = false,
  auto_save = false,

  --- Auto save every second if file
  --- has been changed
  auto_save_interval = 1000
}

M.setup = function(config)
  if not config then
    config = {}
  end

  -- Updates default_config with user options
  for k, v in pairs(config) do
    M.options[k] = v
  end
end

return M