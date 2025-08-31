local M = {}

function M.setup()
  local marp = require("marp-dev-preview")
  local config = require("marp-dev-preview.config")
  local state = require("marp-dev-preview.state")

  vim.api.nvim_create_augroup("MarpDevPreview", { clear = true })

  vim.api.nvim_create_autocmd({ "FileType" }, {
    group = "MarpDevPreview",
    pattern = "markdown",
    callback = function(args)
      if not marp.is_marp() then
        -- set_auto_save and set_live_sync will refuse to start
        -- and notify the user, no need to notify the user on
        -- autoloading. Simply bail out.
        return
      end

      marp.set_auto_save(config.options.auto_save)
      marp.set_live_sync(config.options.live_sync)
    end
  })

  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function(args)
      -- cannot use set_auto_save(false) because bufnr will
      -- not be retrievable after the buffer is unloaded
      if state.timers[args.buf] then
        marp._clear_timer(args.buf)
      end
    end
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function()
      if marp.is_live_sync_on() then
        marp.goto_current_slide()
      end
    end
  })
end

return M