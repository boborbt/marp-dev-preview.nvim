local mdp = require('marp-dev-preview')
local eq = assert.are.same

describe('marp-dev-previoew methods:', function()

-- Mocking various objects. _G will contain the parameters and the
-- return values of the mocked functions
local _G = {
  -- server_cmd
  sc = {
    cmd = nil,
    args = nil,
    ok = true,
    response = { body="success" }
  },

  -- vim.notify
  notify = {
    orig = vim.notify,
    str = nil,
    lvl = nil
  },

  -- vim.fn.input
  input = {
    orig = vim.fn.input,
    usr_input = nil
  }
}

before_each(function()
  mdp.server_cmd = function(cmd, args)
    _G.sc.cmd = cmd
    _G.sc.args = args
    return _G.sc.ok, _G.sc.response
  end

  vim.notify = function(str, level)
    _G.notify.str = str
    _G.notify.lvl = level
  end

  vim.fn.input = function(_)
    return _G.input.usr_input
  end
end)

after_each(function()
  _G.sc.cmd = nil
  _G.sc.args = nil
  _G.sc.ok = true
  _G.sc.response = { body="success" }

  vim.notify = _G.notify.orig
  _G.notify.str = nil
  _G.notify.lvl = nil

  vim.fn.input = input
  _G.input.usr_input = nil

  os.remove('test.md')
end)

function setup_marp_file()
    -- create a marp file
    local file = io.open("test.md", "w")
    file:write("---\nmarp:true\n---\n")
    file:close()

    vim.cmd("edit test.md")
end

function setup_md_file()
    -- create a marp file
    local file = io.open("test.md", "w")
    file:write("# Some markdown file \ncontaining some *md* code\non multiple lines")
    file:close()

    vim.cmd("edit test.md")
end

describe('is_marp', function()
  it('returns false on non-markdown non-marp files', function()
    vim.cmd("enew")

    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "hello",
      "world",
    })

    assert.is.False(mdp.is_marp())
  end)

  it('returns false on markdown non-marp files', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")

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
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")

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
    _G.input.usr_input = "10"

    mdp.goto_slide()

    eq("goto", _G.sc.cmd)
    eq({ key="slide", value=10}, _G.sc.args)
  end)

  it('notifies the user in case of server error', function()
    _G.sc.ok = false
    _G.sc.response = { body = "error body" }

    _G.input.usr_input = "10"

    mdp.goto_slide()

    eq("goto", _G.sc.cmd)
    eq({ key="slide", value=10 }, _G.sc.args)
    eq("Failed to go to slide: error body", _G.notify.str)
    eq(vim.log.levels.ERROR, _G.notify.lvl)
  end)

  it('does not call the server and notifies the user in case the inserted slide number is not a number', function()
    _G.input.usr_input = "xx"

    mdp.goto_slide()

    assert.is.Nil(_G.sc.cmd)
    assert.is.Nil(_G.sc.args)
    eq("xx is not a valid number", _G.notify.str)
  end)
end)

describe('find', function()
  it('correctly invokes server find function (success case)', function()
    _G.input.usr_input = "search term"

    mdp.find()

    eq("find", _G.sc.cmd)
    eq({ key = "string", value = "search term" }, _G.sc.args)
  end)

  it('notifies the user in case of server error', function()
    _G.sc.ok = false
    _G.sc.response = { body = "error body" }
    _G.input.usr_input = "search term"

    mdp.find()

    eq("find", _G.sc.cmd)
    eq({ key = "string", value = "search term" }, _G.sc.args)
    eq("Failed to search: error body", _G.notify.str)
    eq(vim.log.levels.ERROR, _G.notify.lvl)

  end)

  it('does not call the server if the inserted string is empty', function()
    _G.input.usr_input = ""

    mdp.find()

    assert.is.Nil(_G.sc.cmd)
    assert.is.Nil(_G.sc.args)
  end)
end)

describe('live_sync option:', function()
  it('if on live_sync will be enabled on marp files', function()
    -- setup
    mdp.setup({ live_sync = true })

    setup_marp_file()

    assert.is.True(mdp.is_live_sync_on())

  end)
end)

describe('toggle_live_sync', function()
  it('toggles live_sync on and calls goto_current_slide', function()
    local goto_current_slide_called = false
    local original_goto_current_slide = mdp.goto_current_slide
    mdp.goto_current_slide = function()
      goto_current_slide_called = true
    end

    -- Ensure live_sync is off initially
    mdp.setup({live_sync = false})

    setup_marp_file()

    assert.is.False(mdp.is_live_sync_on())

    mdp.toggle_live_sync()

    assert.is.Nil(_G.notify.str)
    assert.is.True(mdp.is_live_sync_on())
    assert.is.True(goto_current_slide_called)

    mdp.goto_current_slide = original_goto_current_slide
  end)

  it('toggles live_sync off', function()
    -- Ensure live_sync is on initially
    mdp.setup({live_sync = true})

    mdp.toggle_live_sync()

    assert.is.False(mdp.is_live_sync_on())
  end)
end)

describe('goto_current_slide', function()
  it('calls _goto_slide with the current slide number', function()
    local goto_slide_called_with = nil
    local original_goto_slide = mdp._goto_slide
    mdp._goto_slide = function(slide_number)
      goto_slide_called_with = slide_number
    end

    local original_current_slide_number = mdp.current_slide_number
    mdp.current_slide_number = function()
      return 5
    end

    mdp.goto_current_slide()

    eq(5, goto_slide_called_with)

    mdp._goto_slide = original_goto_slide
    mdp.current_slide_number = original_current_slide_number
  end)

  it('does not call _goto_slide if the slide number is the same as the last one', function()
    local goto_slide_called = false
    local original_goto_slide = mdp._goto_slide
    mdp._goto_slide = function(slide_number)
      goto_slide_called = true
    end

    local original_current_slide_number = mdp.current_slide_number
    mdp.current_slide_number = function()
      return 5
    end

    mdp.goto_current_slide()

    assert.is.False(goto_slide_called)

    mdp._goto_slide = original_goto_slide
    mdp.current_slide_number = original_current_slide_number
  end)
end)

describe('auto_save option:', function()
  it('clear timers on closing buffers', function()
    -- setup
    mdp.setup({ auto_save = true })

    setup_marp_file()

    assert.is.True(mdp.auto_save_is_on())

   local cur_buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_delete(cur_buf, { force = true })
    -- mdp._clear_timer(cur_buf)

    local timers = mdp._get_timers()
    assert.is.Nil(timers[cur_buf])
  end)



  it('if on causes autosaving on marp files', function()
    -- setup
    mdp.setup({ auto_save = true })

    setup_marp_file()

    assert.is.True(mdp.auto_save_is_on())

  end)

  it('if on does not cause autosaving on non-marp files', function()
    -- setup
    mdp.setup({ auto_save = true })

    setup_md_file()

    assert.is.False(mdp.auto_save_is_on())
  end)

  it('if off makes autosave not automatic', function()
     -- setup
    mdp.setup({ auto_save = false })

    setup_marp_file()

    assert.is.False(mdp.auto_save_is_on())

  end)
end)

describe('toggle_auto_save', function()
  it('does not toggle auto_save if the file is not a marp file', function()
    local original_is_marp = mdp.is_marp
    mdp.is_marp = function() return false end

    local auto_save_is_on_called = false
    local original_auto_save_is_on = mdp.auto_save_is_on
    mdp.auto_save_is_on = function()
      auto_save_is_on_called = true
      return false
    end

    mdp.toggle_auto_save()

    assert.is.False(auto_save_is_on_called)

    mdp.is_marp = original_is_marp
    mdp.auto_save_is_on = original_auto_save_is_on
  end)

  it('toggles auto_save on for a marp file', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "---",
      "marp:true",
      "---"
    })

    -- Ensure auto_save is off initially
    if mdp.auto_save_is_on() then
      mdp.toggle_auto_save()
    end

    mdp.toggle_auto_save()

    assert.is.True(mdp.auto_save_is_on())

    -- cleanup
    mdp.toggle_auto_save()
  end)

  it('toggles auto_save off for a marp file', function()
    vim.cmd("enew")
    vim.cmd("set filetype=markdown")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "---",
      "marp:true",
      "---"
    })

    -- Ensure auto_save is on initially
    if not mdp.auto_save_is_on() then
      mdp.toggle_auto_save()
    end

    mdp.toggle_auto_save()

    assert.is.False(mdp.auto_save_is_on())
  end)
end)

end)
