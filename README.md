# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate Marp Dev Preview into NeoVim with slide syncing and quick navigation.

---

# Marp Dev Preview - NeoVim Plugin

Seamlessly integrate Marp Dev Preview into NeoVim with slide syncing and quick navigation.

---

## Quick Start

**Install with `lazy.nvim`:**

```lua
use {
  'boborbt/marp-dev-preview.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('marp-dev-preview').setup({ auto_sync = true })
  end
}
```

**Suggested Keybindings:**

```lua
vim.api.nvim_set_keymap('n', '<leader>mt', '<cmd>MarpDevPreviewToggleLiveSync<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mg', '<cmd>MarpDevPreviewGoto<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mf', '<cmd>MarpDevPreviewFind<CR>', { noremap = true, silent = true })
```

Or use the Lua API directly:

```lua
require('marp-dev-preview').toggle_auto_sync()
require('marp-dev-preview').goto()
require('marp-dev-preview').find()
```

---

## Features

- **Auto Sync Slides** – Keep your Markdown slide position synced with the preview.  
  (*One-way sync: browser → NeoVim not supported.*)  
- **Goto Slide** – Jump to a specific slide. Temporarily disables auto-sync.  
- **Find String** – Search text in the preview. Temporarily disables auto-sync.  

---

## Configuration

```lua
require('marp-dev-preview').setup({
  auto_sync = true, -- boolean: enable/disable auto-sync (default: true)
})
```

---

## Contributing

I’m new to Lua and NeoVim plugin development. Feedback, issues, and pull requests are welcome! Help improve the plugin for everyone.


## Quick Start

**Install with `lazy.nvim`:**

```lua
use {
  'boborbt/marp-dev-preview.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('marp-dev-preview').setup({ auto_sync = true })
  end
}
```

**Suggested Keybindings:**

```lua
vim.api.nvim_set_keymap('n', '<leader>mt', '<cmd>MarpDevPreviewToggleLiveSync<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mg', '<cmd>MarpDevPreviewGoto<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>mf', '<cmd>MarpDevPreviewFind<CR>', { noremap = true, silent = true })
```

Or use the Lua API directly:

```lua
require('marp-dev-preview').toggle_auto_sync()
require('marp-dev-preview').goto()
require('marp-dev-preview').find()
```

---

## Configuration

```lua
require('marp-dev-preview').setup({
  auto_sync = true, -- boolean: enable/disable auto-sync (default: true)
})
```

---

## Contributing

I’m new to Lua and NeoVim plugin development. Feedback, issues, and pull requests are welcome! Help improve the plugin for everyone.

