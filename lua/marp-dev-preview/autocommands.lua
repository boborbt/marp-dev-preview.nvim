local M = {}

function M.setup()
  local marp = require("marp-dev-preview")
  local config = require("marp-dev-preview.config")
  local state = require("marp-dev-preview.state")
  local server = require("marp-dev-preview.server")
  local utils = require("marp-dev-preview.utils")

  vim.api.nvim_create_augroup("MarpDevPreview", { clear = true })

  local function send_latest_refresh(bufnr)
    local refresh_state = state.refresh[bufnr]
    if not refresh_state or not refresh_state.pending then
      return
    end

    local markdown = refresh_state.pending
    refresh_state.pending = nil
    refresh_state.running = true

    server.refresh_async(markdown, function(ok)
      local current_state = state.refresh[bufnr]
      if not current_state then
        return
      end

      current_state.running = false

      if not ok then
        marp.set_live_sync(false)
        return
      end

      if current_state.pending then
        send_latest_refresh(bufnr)
      end
    end)
  end

  local function schedule_refresh(bufnr)
    local refresh_state = state.refresh[bufnr]
    if not refresh_state then
      refresh_state = {}
      state.refresh[bufnr] = refresh_state
    end

    if refresh_state.timer then
      refresh_state.timer:stop()
    else
      refresh_state.timer = vim.loop.new_timer()
    end

    refresh_state.timer:start(config.options.live_sync_debounce, 0, function()
      vim.schedule(function()
        local current_state = state.refresh[bufnr]
        if not current_state then
          return
        end

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        current_state.pending = table.concat(lines, "\n")

        if not current_state.running then
          send_latest_refresh(bufnr)
        end
      end)
    end)
  end

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

      if not server.is_running() then
        return
      end

      marp.set_live_sync(config.options.live_sync)
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function()
      if not marp.is_live_sync_on() then
        return
      end

      local ok, _ = marp.goto_current_slide()
      if not ok then
        vim.notify("Failed to sync current slide ", vim.log.levels.ERROR)
        marp.set_live_sync(false)
        return
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function(args)
      if not marp.is_live_sync_on() then
        return
      end

      vim.notify("Scheduling refresh for buffer: " .. args.buf, vim.log.levels.DEBUG)
      schedule_refresh(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = "MarpDevPreview",
    pattern = "*.md",
    callback = function(args)
      local bufnr = args.buf
      state.live_buffers[bufnr] = nil
      local refresh_state = state.refresh[bufnr]
      if refresh_state and refresh_state.timer then
        refresh_state.timer:stop()
        refresh_state.timer:close()
      end
      state.refresh[bufnr] = nil
      local any_live = false
      for _, live in pairs(state.live_buffers) do
        any_live = any_live or live
      end

      local filename = vim.api.nvim_buf_get_name(bufnr)

      if not any_live and server.is_running() then
        server.stop(filename)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = "MarpDevPreview",
    pattern = "*",
    callback = function()
      server.stop_all()
    end,
  })

  --- creates text objects for marp slides
  vim.api.nvim_create_autocmd("FileType", {
    group = "MarpDevPreview",
    pattern = "markdown",
    callback = function(event)
      -- abort if not marp file
      if not utils.is_marp() then
        return
      end

      local opts = { buffer = event.buf, silent = true }

      vim.keymap.set({ "o", "x" }, "iS", function()
        marp.select_slide(false)
      end, vim.tbl_extend("force", opts, { desc = "Inner Marp slide" }))

      vim.keymap.set({ "o", "x" }, "aS", function()
        marp.select_slide(true)
      end, vim.tbl_extend("force", opts, { desc = "Around Marp slide" }))

      vim.keymap.set({ "n", "o", "x" }, "]S", function()
        marp.next_slide()
      end, vim.tbl_extend("force", opts, { desc = "Next Marp slide" }))

      vim.keymap.set({ "n", "o", "x" }, "[S", function()
        marp.prev_slide()
      end, vim.tbl_extend("force", opts, { desc = "Previous Marp slide" }))

      vim.keymap.set({ "o", "x" }, "iC", function()
        marp.select_box(false)
      end, vim.tbl_extend("force", opts, { desc = "Inner Marp container" }))

      vim.keymap.set({ "o", "x" }, "aC", function()
        marp.select_box(true)
      end, vim.tbl_extend("force", opts, { desc = "Around Marp container" }))

      vim.keymap.set({ "n", "o", "x" }, "]C", function()
        marp.goto_next_box()
      end, vim.tbl_extend("force", opts, { desc = "Next Marp container" }))

      vim.keymap.set({ "n", "o", "x" }, "[C", function()
        marp.goto_prev_box()
      end, vim.tbl_extend("force", opts, { desc = "Previous Marp container" }))
    end,
  })
end

return M
