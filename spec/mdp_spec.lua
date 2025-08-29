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

    assert.is.False(mdp.is_marp())
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

    assert.is.False(mdp.is_marp())
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

    assert.is.False(mdp.is_marp())
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


    assert.is.True(mdp.is_marp())
  end)
end)


describe('current_slide_number', function()
  it('returns -1 on empty file', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")

    eq(mdp.current_slide_number(), -1)
  end)

  it('returns 0 when cursor is before the first slide', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")
    vim.api.nvim_buf_set_lines(0,0,-1,false, {
      "---",
      "marp:true",
      "---",
      "first slide",
      "---",
      "second slide",
      "---",
      "third slide"
    })
    vim.cmd("1")

    eq(0, mdp.current_slide_number())
  end)

  it('returns the corret slide number when cursor is in the middel of the file', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")
    vim.api.nvim_buf_set_lines(0,0,-1,false, {
      "---",
      "marp:true",
      "---",
      "first slide",
      "---",
      "second slide",
      "---",
      "third slide"
    })
    vim.cmd("6")

    eq(2, mdp.current_slide_number())
  end)

  it('returns the number of last slide when cursor is at the end of the file', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")
    vim.api.nvim_buf_set_lines(0,0,-1,false, {
      "---",
      "marp:true",
      "---",
      "first slide",
      "---",
      "second slide",
      "---",
      "third slide"
    })
    vim.cmd("8")

    eq(3, mdp.current_slide_number())
  end)

end)

describe('goto_slide', function()
  it('correctly invokes server goto function (success case)', function()
    local sc_cmd
    local sc_args

    -- mocks the server_cmd function so that the
    -- server is not really invoked
    mdp.server_cmd = function(cmd, args)
      sc_cmd = cmd
      sc_args = args
      return true, { body="success" }
    end

    local fn_input = vim.fn.input
    vim.fn.input = function(args)
      return "10"
    end

    mdp.goto_slide()

    eq("goto", sc_cmd)
    eq({ key="slide", value=10}, sc_args)

    vim.fn.input = fn_input
  end)

  it('does not call the server and notifies the user in case the inserted slide number is not a number', function()
    local sc_cmd
    local sc_args

    -- mocks the server_cmd function so that the
    -- server is not really invoked
    mdp.server_cmd = function(cmd, args)
      sc_cmd = cmd
      sc_args = args
      return true, { body="success" }
    end

    local fn_input = vim.fn.input
    vim.fn.input = function(args)
      return "xx"
    end

    local notify_str
    local notify = vim.fn.notify
    vim.notify = function(str)
      notify_str = str
    end

    mdp.goto_slide()

    assert.is.Nil(sc_cmd)
    assert.is.Nil(sc_args)
    eq("xx is not a valid number", notify_str)

    vim.fn.input = fn_input
    vim.notify = notify
  end)



end)



