" Title:        Example Plugin
" Description:  A plugin to provide an example for creating Neovim plugins.
" Last Change:  8 November 2021
" Maintainer:   Example User <https://github.com/example-user>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_marp_dev_preview_plugin")
    finish
endif
let g:loaded_marp_dev_preview_plugin= 1

" Defines a package path for Lua. This facilitates importing the
" Lua modules from the plugin's dependency directory.
let s:plenary_path = expand('<sfile>:p:h:h') . '/lua/marp-dev-preview/deps/plenary.nvim/lua'
exe "lua package.path = package.path .. ';" . s:plenary_path . "/?.lua'"
exe "lua package.path = package.path .. ';" . s:plenary_path . "/?/init.lua'"

" Exposes the plugin's functions for use as commands in Neovim.
command! -nargs=0 MarpDevPreviewToggleLiveSync lua require("marp-dev-preview").toggle_live_sync()
command! -nargs=0 MarpDevPreviewStartLiveSync lua require("marp-dev-preview").set_live_sync(true)
command  -nargs=0 MarpDevPreviewStopLiveSync lua require("marp-dev-preview").set_live_sync(false)
command! -nargs=0 MarpDevPreviewGoTo lua require("marp-dev-preview").goto_slide()
command! -nargs=0 MarpDevPreviewStartServer lua require("marp-dev-preview").start_server()
command! -nargs=0 MarpDevPreviewStopServer lua require("marp-dev-preview").stop_server()
command! -nargs=0 MarpDevPreviewStartAll lua require("marp-dev-preview").start_server_and_live_syn()
command! -nargs=0 MarpDevPreviewNextSlide lua require("marp-dev-preview").next_slide()
command! -nargs=0 MarpDevPreviewPrevSlide lua require("marp-dev-preview").prev_slide()
command! -nargs=1 MarpDevPreviewAttach lua require("marp-dev-preview").attach_to_server(<f-args>)
