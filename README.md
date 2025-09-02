# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate [Marp Dev Preview](https://github.com/boborbt/marp-dev-preview) into NeoVim with slide syncing and quick navigation.

## Features

- **Live Sync Slides**
  - Updates the preview as you edit your Markdown slides (rendering incrementally at each buffer change).
  – Keep your Markdown slide position synced with the preview.  (*One-way sync: browser → NeoVim not supported.*)
- **Goto Slide** – Jump to a specific slide. Temporarily disables auto-sync.
- **Find String** – Search text in the preview. Temporarily disables auto-sync.

---

## Quick Start

**Install with `lazy.nvim`:**

```lua
use {
  'boborbt/marp-dev-preview.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('marp-dev-preview').setup({ })
  end
}
```
The plugin **does not** start the Marp Dev Preview server for you. Please follow the instructions in the [Marp Dev Preview repository](github.com/boborbt/marp-dev-preview) to set it up.

In brief, the easiest way is to use npx:

```bash
  npx marp-dev-preview --theme-dir <path-to-your-marp-themes> <path-to-your-markdown-file>
```

Then just open your browser at "localhost:8080" and the same markdown file in NeoVim. If you have `live_sync` enabled in the plugin config, the preview will automatically start syncing as you edit the file. Otherwise, you can manually toggle live sync with:

```vim
:MarpDevPreviewToggleLiveSync
```
Other commands you might find useful:

```vim
:MarpDevPreviewGoto
:MarpDevPreviewFind
```

- MarpDevPreviewGoto allows you to jump to a specific slide.
- MarpDevPreviewFind allows you to search for a string in the preview (it will find the first occurrence).

**Note**: MarpDevPreviewGoto and MarpDevPreviewFind will temporarily disable live sync until you toggle it back on.


**Suggested Keybindings:**

```lua
vim.api.nvim_set_keymap('n', '<leader>mt', '<cmd>MarpDevPreviewToggleLiveSync<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mg', '<cmd>MarpDevPreviewGoto<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mf', '<cmd>MarpDevPreviewFind<CR>', { noremap = true, silent = true })
```

Or use the Lua API directly:

```lua
require('marp-dev-preview').toggle_live_sync()
require('marp-dev-preview').goto_slide()
require('marp-dev-preview').find()
```

---

## Configuration

You can customize the plugin by passing options to the `setup` function. Here are the available options and their default values:

 Option              | Type    | Default | Description
---------------------|---------|---------|-----------------------------------------------------------------------------------------------
 `live_sync`         | boolean | `false` | If true automatically enables live_sync for a newly opened marp file.
 `timeout`           | number  | `5000`  | Timeout in milliseconds for connecting to the [marp-dev-preview](https://github.com/boborbt/marp-dev-preview) server.
 `port`              | number  | `8080`  | Port number where the [marp-dev-preview](https://github.com/boborbt/marp-dev-preview) server is running.



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
