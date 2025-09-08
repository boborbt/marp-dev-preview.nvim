local M = {}

M.options = {
  -- marp-dev-preview server port
  port = 8080,
  -- marp-dev-preview server connection_timeout
  server_cmds_timeout = 1000,
  server_start_timeout = 3000,
  live_sync_start_timeout = 3000,

  live_sync = false,

  theme_dir = nil
}

M.setup = function(config)
  if not config then
    config = {}
  end

  -- Updates default_config with user options
  for k, v in pairs(config) do
    M.options[k] = v
  end

  vim.api.nvim_set_hl(0, "LiveSyncOn", { fg = "#00ff00" })
  vim.api.nvim_set_hl(0, "LiveSyncOff",  { fg = "#ff0000" })
end

return M
