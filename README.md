# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate [Marp Dev Preview](https://github.com/boborbt/marp-dev-preview) into NeoVim with slide syncing and quick navigation.

## Features

- **Starts/stops the preview server** (experimental)
- **Live Sync Slides**
  - Updates the preview as you edit your Markdown slides (rendering incrementally at each buffer change).
  – Keep your Markdown slide position synced with the preview.  (*One-way sync: browser → NeoVim not supported.*)
- **Goto Slide** – Jump to a specific slide. Temporarily disables auto-sync.

---

## Quick Start

**Install with the plugin manager of your choice, here is a `lazy.nvim`** example (below you can find my complete lazy.nvim configuration):

```lua
use {
  'boborbt/marp-dev-preview.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('marp-dev-preview').setup({ })
  end
}
```
The plugin provides experimental support to start the Marp Dev Preview server for you. If you prefer to start it yourself, you can follow the instructions in the [Marp Dev Preview server repository](github.com/boborbt/marp-dev-preview) to set the server up.

In brief, the easiest way to start the server is via npx:

```bash
  npx marp-dev-preview --theme-dir <path-to-your-marp-themes> <path-to-your-markdown-file>
```

Then just open your browser at "localhost:8080" and the same markdown file in NeoVim. To start Live Sync, use the command below.

```vim
:MarpDevPreviewStartLiveSync
```
Other commands you might find useful:

```vim
:MarpDevPreviewStartServer
:MarpDevPreviewStopServer
:MarpDevPreviewStartLiveSync
:MarpDevPreviewStopLiveSync
:MarpDevPreviewToggleLiveSync
:MarpDevPreviewGoto
:MarpDevPreviewFind
```

- **MarpDevPreviewStartServer** starts the Marp Dev Preview server from within NeoVim (experimental).
- **MarpDevPreviewStopServer** stops the Marp Dev Preview server started from within NeoVim.
- **MarpDevPreviewStartLiveSync** enables live sync between your markdown file and the preview, it will not work if the server is not running.
- **MarpDevPreviewStopLiveSync** disables live sync.
- **MarpDevPreviewToggleLiveSync** toggles live sync on or off.
- **MarpDevPreviewGoto** allows you to jump to a specific slide within your markdown file (if live sync is enabled, the preview will update accordingly).


**LazyVim configuration example with key mappings:**

```lua
return {
  "boborbt/marp-dev-preview.nvim",
  branch = "server-start",
  lazy = false,
  config = function()
    mdp = require('marp-dev-preview')
    mdp.setup({
      live_sync = true,
      theme_dir = "theme/themes"
    })
  end,

  keys = {
    {
      "<leader>ms",
      "<cmd>MarpDevPreviewStartServer<cr>",
      desc = "Marp: start server",
      mode = "n"
    },
    {
      "<leader>mS",
      "<cmd>MarpDevPreviewStopServer<cr>",
      desc = "Marp: stop server",
      mode = "n"
    },
    {
      "<leader>ml",
      "<cmd>MarpDevPreviewStartLiveSync<cr>",
      desc = "Marp: start live sync",
      mode = "n"
    },
    {
      "<leader>mL",
      "<cmd>MarpDevPreviewStopLiveSync<cr>",
      desc = "Marp: stop live sync",
      mode = "n"
    },
    {
      "<leader>mx",
      function()
          vim.notify("starting marp")
          mdp.start_server()
          -- add a delay to allow the server to start before
          -- enabling live sync
          timer = vim.loop.new_timer()
          timer:start(1000, 0, vim.schedule_wrap(function()
            mdp.set_live_sync(true)
            timer:stop()
            timer:close()
          end))
        end,
      desc = "Marp: start server and live sync",
      mode = "n"
    },
    {
      "<leader>mX",
      "<cmd>MarpDevPreviewStopLiveSync<cr><cmd>MarpDevPreviewStopServer<cr>",
      desc = "Marp: stop live sync and server",
      mode = "n"
    },
  }
}
```

---

## Configuration

You can customize the plugin by passing options to the `setup` function. Here are the available options and their default values:

 Option              | Type    | Default | Description
---------------------|---------|---------|-----------------------------------------------------------------------------------------------
 `live_sync`         | boolean | `false` | If true automatically enables live_sync for a newly opened marp file when the server is running.
 `timeout`           | number  | `5000`  | Timeout in milliseconds for trying to establish a connection with [marp-dev-preview](https://github.com/boborbt/marp-dev-preview) server.
 `port`              | number  | `8080`  | Port number for the connection with [marp-dev-preview](https://github.com/boborbt/marp-dev-preview).



Defaults:

```lua
require('marp-dev-preview').setup({
  live_sync = false,

  -- Marp Dev Preview server options
  timeout = 5000,
  port = 8080
})
```

---

## Contributing

I’m new to Lua and NeoVim plugin development. Feedback, issues, and pull requests are welcome! Help improve the plugin for everyone.

I'm opening issues for enhancements and bugs as I find them. Feel free to peruse them if you're looking for something to work on.
