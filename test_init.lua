-- init nvim file for testing the plugin, launch the tests using:
--  nvim --headless -u test_init.lua -c 'PlenaryBustedDirectory spec'

package.path = package.path .. ';/Users/robertoesposito/.luarocks/share/lua/5.1/?.lua'

vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend('lua/marp-dev-preview/deps/plenary.nvim')

require('marp-dev-preview')
