local M = {}

function M.setup()
  local marp = require("marp-dev-preview")
  local config = require("marp-dev-preview.config")
  local state = require("marp-dev-preview.state")
  local server = require("marp-dev-preview.server")
  local utils = require("marp-dev-preview.utils")

  vim.api.nvim_create_augroup("MarpDevPreview", { clear = true })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = "MarpDevPreview",
    pattern = "markdown",
    callback = function(args)
      if not utils.is_marp() then
        -- set_live_sync will refuse to start
        -- and notify the user, no need to notify the user on
        -- autoloading. Simply bail out.
        return
      end

      marp.set_live_sync(config.options.live_sync)
    end
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function()
      if not marp.is_live_sync_on() then
        return
      end

      ok, _ = marp.goto_current_slide()
      if not ok then
        vim.notify("Failed to sync current slide ", vim.log.levels.ERROR)
        marp.set_live_sync(false)
        return
      end
    end
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function()
      if not marp.is_live_sync_on() then
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      vim.notify("Refreshing buffer: " .. bufnr, vim.log.levels.DEBUG)

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local text = table.concat(lines, "\n")
      local ok, response = server.refresh(text)

      if not ok then
        marp.set_live_sync(false)
        return
      end
    end
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function(args)
      local bufnr = args.buf
      state.live_buffers[bufnr] = nil

      local any_live = false
      for _, v in pairs(state.live_buffers) do
        if v then
          any_live = true
          break
        end
      end

      if not any_live and server.is_running() then
        server.stop()
      end
    end
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = "MarpDevPreview",
    pattern = "*",
    callback = function()
      if server.is_running() then
        server.stop()
      end
    end
  })
end

return M
