# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate [Marp Dev Preview](https://github.com/boborbt/marp-dev-preview) into NeoVim with slide syncing and quick navigation.

### Warning

Currently the plugin **has been only tested on MacOS**. Please open an issue if you encounter any problems on other operating systems, but keep in mind that I don't have access to windows machines (but I'm happy to review and merge PRs fixing issues on windows).

## Features

- **Starts/stops the preview server** (experimental)
- **Live Sync Slides**
  - Updates the preview as you edit your Markdown slides (rendering incrementally at each buffer change).
  - Keep your Markdown slide position synced with the preview.  (*One-way sync: browser → NeoVim not supported.*)
- **Goto Slide** – Jump to a specific slide. Temporarily disables auto-sync.
- **Next/Prev Slides** - provides commands to navigate to the next/previous slide in your markdown file.

---

<center>
  
  ![mdp-live-demo](https://github.com/user-attachments/assets/47c8d593-1ae6-4632-a0a8-cd6ddb5f5efa)

</center>

---

## Quick Start

**Install with the plugin manager of your choice, here is a `lazy.nvim`** example (at the end of this README you can find a complete lazy.nvim example with key mappings):

```lua
use {
  'boborbt/marp-dev-preview.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('marp-dev-preview').setup({ })
  end
}
```
The plugin provides experimental support to start the Marp Dev Preview server for you. If you prefer to start it yourself, you can follow the instructions in the [Marp Dev Preview server repository](github.com/boborbt/marp-dev-preview) to set the server up. And use MarpDevPreviewStartAttach command to connect your marp buffer with the server.

To start the server and the live sync, run the following command in NeoVim:

```vim
:MarpDevPreviewStartAll
```

Other commands you might find useful:

```vim
:MarpDevPreviewStartServer
:MarpDevPreviewStopServer
:MarpDevPreviewStartLiveSync
:MarpDevPreviewStopLiveSync
:MarpDevPreviewToggleLiveSync
:MarpDevPreviewGoto
:MarpDevPreviewNextSlide
:MarpDevPreviewPrevSlide
:MarpDevPreviewStartAttach
```

- **MarpDevPreviewStartAll** starts the Marp Dev Preview server (if not already running), opens a browser on the preview page, and enables live sync.
- **MarpDevPreviewStartServer** starts the Marp Dev Preview server from within NeoVim (experimental) and opens a browser on the preview page.
- **MarpDevPreviewStopServer** stops the Marp Dev Preview server started from within NeoVim.
- **MarpDevPreviewStartLiveSync** enables live sync between your markdown file and the preview, it will not work if the server is not running. You can provide as an argument the port number on which the server is running (not necessary if you started the server from within NeoVim).
- **MarpDevPreviewStopLiveSync** disables live sync.
- **MarpDevPreviewToggleLiveSync** toggles live sync on or off.
- **MarpDevPreviewGoto** allows you to jump to a specific slide within your markdown file (if live sync is enabled, the preview will update accordingly).
- **MarpDevPreviewNextSlide** jumps to the next slide in your markdown file (if live sync is enabled, the preview will update accordingly).
- **MarpDevPreviewPrevSlide** jumps to the previous slide in your markdown file (if live sync is enabled, the preview will update accordingly).
- **MarpDevPreviewStartAttach** connects your marp buffer with a running Marp Dev Preview server. You can provide as an argument the port number on which the server is running.

---

## Configuration

You can customize the plugin by passing options to the `setup` function. Here are the available options and their default values:

 Option              | Type    | Default | Description
---------------------|---------|---------|-----------------------------------------------------------------------------------------------
 `server_start_timeout`           | number  | `3000`  | Timeout in milliseconds for trying to establish a connection with [marp-dev-preview](https://github.com/boborbt/marp-dev-preview) server.
`server_cmds_timeout`            | number  | `1000`  | Timeout in milliseconds for server operations.
`live_sync_start_timeout`       | number  | `3000`  | Timeout in milliseconds for trying to start live sync. If the server is not running or not reachable within this time, an error will be shown.
 `port`              | number  | `8080`  | *base* port number for the connection with [marp-dev-preview](https://github.com/boborbt/marp-dev-preview). The plugin will try to connect to a random port computed as `port + n` where `n` is a random number between 0 and 1000. This is to avoid port conflicts if you run multiple instances of NeoVim or if you want to connect to different presentations.
`theme_set`        | array | {}   | If set, it will be passed to the Marp Dev Preview server as the `--theme-set` argument. See [Marp Dev Preview server documentation](https://github.com/boborbt/marp-dev-preview) for details. The directory should be relative to the position of the marp file being edited.

Defaults:

```lua
require('marp-dev-preview').setup({
  -- timeout for server operations in milliseconds
  server_cmds_timeout = 1000,

  -- timeout for server startup in milliseconds
  server_start_timeout = 3000,
:
  -- timeout for live sync start in milliseconds
  live_sync_start_timeout = 3000,

  -- base port for the marp-dev-preview server
  port = 8080,

  -- directory containing custom themes, relative to the marp file being edited
  theme_set = nil
})
```

---

## Contributing

I’m new to Lua and NeoVim plugin development. Feedback, issues, and pull requests are welcome! Help improve the plugin for everyone.

I'm opening issues for enhancements and bugs as I find them. Feel free to peruse them if you're looking for something to work on.

---

## Complete lazy.nvim configuration example with key mappings:**

```lua
return {
  "boborbt/marp-dev-preview.nvim",
  branch = "server-start",
  lazy = false,
  config = function()
    mdp = require('marp-dev-preview')
    mdp.setup({
      live_sync = true,
      theme_set = { "theme" }
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
      "<leader>mx", function() mdp.start_server_and_live_sync() end,
      desc = "Marp: start live sync and server",
    },
    {
      "<leader>mX",
      "<cmd>MarpDevPreviewStopLiveSync<cr><cmd>MarpDevPreviewStopServer<cr>",
      desc = "Marp: stop live sync and server",
      mode = "n"
    },
    {
      "<leader>mg",
      "<cmd>MarpDevPreviewGoTo<cr>",
      desc = "Marp: go to slide",
    },
    {
      "<C-n>",
      "<cmd>MarpDevPreviewNextSlide<cr>zz",
      desc = "Marp: next slide",
      mode = "n"
    },
    {
      "<C-p>",
      "<cmd>MarpDevPreviewPrevSlide<cr>zz",
      desc = "Marp: previous slide",
      mode = "n"
    },
  }
}
```


