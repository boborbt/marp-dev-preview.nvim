package.path = package.path .. ';/Users/robertoesposito/.luarocks/share/lua/5.1/?.lua'

require('luacov')--  nvim --headless -u test_init.lua -c 'PlenaryBustedDirectory spec'
print('luacov loaded')

vim.opt.rtp:prepend('.')
vim.opt.rtp:prepend('lua/marp-dev-preview/deps/plenary.nvim')

require('marp-dev-preview')
