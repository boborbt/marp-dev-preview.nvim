# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate [Marp Dev Preview](https://github.com/boborbt/marp-dev-preview) into NeoVim with slide syncing and quick navigation.

## Features

- **Auto Sync Slides** – Keep your Markdown slide position synced with the preview.  (*One-way sync: browser → NeoVim not supported.*)  
- **Auto Save Slides** - Automatically save the marp file every 1000ms (configurable)
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

**Suggested Keybindings:**

```lua
vim.api.nvim_set_keymap('n', '<leader>mt', '<cmd>MarpDevPreviewToggleLiveSync<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ms', '<cmd>MarpDevPreviewToggleAutoSave<CR>', { noremap = true, silent = true }) -- save file
vim.api.nvim_set_keymap('n', '<leader>mg', '<cmd>MarpDevPreviewGoto<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mf', '<cmd>MarpDevPreviewFind<CR>', { noremap = true, silent = true })
```

Or use the Lua API directly:

```lua
require('marp-dev-preview').toggle_live_sync()
require('marp-dev-preview').toggle_auto_save()
require('marp-dev-preview').goto_slide()
require('marp-dev-preview').find()
```

---

## Configuration

Currently the only option you can set is `auto_sync` which starts as false by default.

```lua
require('marp-dev-preview').setup({
  auto_sync = true, -- boolean: enable/disable auto-sync (default: true)
})
```

---

## Contributing

I’m new to Lua and NeoVim plugin development. Feedback, issues, and pull requests are welcome! Help improve the plugin for everyone.

