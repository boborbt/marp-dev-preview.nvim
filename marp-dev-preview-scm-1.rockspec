rockspec_format = '3.0'
package = "marp-dev-preview"
version = "scm-1"
source = {
  -- TODO: Update this URL
  url = "git+https://github.com/boborbt/marp-dev-preview.nvim"
}

dependencies = {
  "plenary.nvim"
}
test_dependencies = {
}
build = {
  type = "builtin",
  copy_directories = {
    -- Add runtimepath directories, like
    -- 'plugin', 'ftplugin', 'doc'
    -- here. DO NOT add 'lua' or 'lib'.
  },
}
