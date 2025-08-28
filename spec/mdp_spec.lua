local mdp = require('marp-dev-preview')
local eq = assert.are.same

describe('is_marp', function()
  it('returns false on non-markdown non-marp files', function()
    -- Create a new empty buffer
    vim.cmd("enew")

    -- Insert some lines
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "hello",
      "world",
    })

    eq(mdp.is_marp(), false)
  end)

  it('returns false on markdown non-marp files', function()
    -- Create a new empty buffer
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")

    -- Insert some lines
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "---",
      "hello",
      "world",
    })

    eq(mdp.is_marp(), false)
  end)

  it('returns false on non-markdown marp files', function()
    -- Create a new empty buffer
    vim.cmd("enew")

    -- Insert some lines
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "---",
      "marp:true",
      "---"
    })

    eq(mdp.is_marp(), false)

  end)

  it('returns true on markdown marp files', function()
    -- Create a new empty buffer
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")

    -- Insert some lines
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "---",
      "marp:true",
      "---"
    })

    eq(mdp.is_marp(), true)
  end)
end)
