local mdp = require('marp-dev-preview')
local utils = require('marp-dev-preview.utils')
local server = require('marp-dev-preview.server')
local eq = assert.are.same

describe('marp-dev-preview methods:', function()
  -- Mocking various objects. _G will contain the parameters and the
  -- return values of the mocked functions
  local _G = {
    -- server_cmd
    sc = {
      cmd = nil,
      args = nil,
      ok = true,
      response = { body = "success" }
    },

    -- vim.notify
    notify = {
      orig = vim.notify,
      str = nil,
    },

    -- vim.fn.input
    input = {
      orig = vim.fn.input,
      usr_input = nil
    }
  }

  before_each(function()
    _G.sc.orig = server.server_cmd
    server.server_cmd = function(cmd, args)
      _G.sc.cmd = cmd
      _G.sc.args = args
      return _G.sc.ok, _G.sc.response
    end

    vim.notify = function(str, level)
      if level == vim.log.levels.DEBUG then
        return
      end

      _G.notify.str = str
    end

    vim.fn.input = function(_)
      return _G.input.usr_input
    end
  end)

  after_each(function()
    server.server_cmd = _G.sc.orig
    _G.sc.cmd = nil
    _G.sc.args = nil
    _G.sc.ok = true
    _G.sc.response = { body = "success" }

    vim.notify = _G.notify.orig
    _G.notify.str = nil
    _G.notify.lvl = nil

    vim.fn.input = input
    _G.input.usr_input = nil

    local cur_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_delete(cur_buf, { force = true })
    os.remove('test.md')
  end)

  function setup_marp_file(str)
    if not str then
      str = "---\nmarp:true\n---\n"
    end

    -- create a marp file
    local file = io.open("test.md", "w")
    file:write(str)
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

  describe('config functions', function()
    it('setup can be correctly accessed', function()
      mdp.setup({
        auto_sync = true,
        port = 9898,
        time_out = 42
      })

      assert.is.True(mdp.get('auto_sync'))
      eq(9898, mdp.get('port'))
      eq(42, mdp.get('time_out'))
    end)

    it('get returns nil for non-existing keys', function()
      assert.is.Nil(mdp.get('non_existing_key'))
    end)

    it('get returns the value set via set', function()
      mdp.set('auto_sync', 'bullshit value')
      eq('bullshit value', mdp.get('auto_sync'))
    end)
  end)

  describe('is_marp', function()
    it('returns false on non-markdown non-marp files', function()
      vim.cmd("enew")

      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "hello",
        "world",
      })

      assert.is.False(utils.is_marp())
    end)

    it('returns false on markdown non-marp files', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")

      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "hello",
        "world",
      })

      assert.is.False(utils.is_marp())
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

      assert.is.False(utils.is_marp())
    end)

    it('returns true on marp with style code', function()
      str = table.concat({
        "---\n",
        "marp:true\n",
        "theme: uncover-bb\n",
        "paginate: true\n",
        "---\n",
        "\n",
        "<style>\n",
        "\n",
        "div.course-details {\n",
        "margin-top:2em;\n",
        "font-size: smaller;\n",
        "}\n",
        "\n",
        "div.course-details img {\n",
        "float: left;\n",
        "width: 100px;\n",
        "margin-right: 30px;\n",
        "}\n" })


      setup_marp_file(str)
      assert.is.True(utils.is_marp())
    end)

    it('returns true on markdown marp files', function()
      setup_marp_file()

      assert.is.True(utils.is_marp())
    end)
  end)

  describe('num_slides', function()
    it('returns the total number of slides', function()
      setup_marp_file("---\nmarp: true\n---\nfirst slide\n---\nsecond slide\n---\nthird slide")
      local n = utils.num_slides()
      eq(3, n)
    end)
  end)


  describe('current_slide_number', function()
    it('returns -1 on empty file', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")

      eq(utils.current_slide_number(), -1)
    end)

    it('returns 0 when cursor is before the first slide', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
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

      eq(0, utils.current_slide_number())
    end)

    it('returns the corret slide number when cursor is in the middle of the file', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
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

      eq(2, utils.current_slide_number())
    end)

    it('returns the number of last slide when cursor is at the end of the file', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
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

      eq(3, utils.current_slide_number())
    end)
  end)

  describe('goto_slide', function()
    it('invokes server goto function (success case)', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "---",
        "second slide",
        "---",
        "third slide"
      })

      _G.input.usr_input = "2"

      mdp.goto_slide()

      eq("goto", _G.sc.cmd)
      eq({ key = "slide", value = 2 }, _G.sc.args)
      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it('it reposition the cursor within the selected slide (success case)', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "---",
        "second slide",
        "---",
        "third slide"
      })

      _G.input.usr_input = "2"

      mdp.goto_slide()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it(
      'does not call the server and notifies the user in case the inserted slide number is >= than the total number of slides',
      function()
        vim.cmd("enew")
        vim.cmd("set filetype=markdown")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
          "---",
          "marp:true",
          "---",
          "first slide",
          "---",
          "second slide",
          "---",
          "third slide"
        })

        _G.input.usr_input = "4"

        mdp.goto_slide()

        assert.is.Nil(_G.sc.cmd)
        assert.is.Nil(_G.sc.args)
        eq("4 is not a valid slide number", _G.notify.str)
      end)

    it('does not call the server and notifies the user in case the inserted slide number is <=0', function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "---",
        "second slide",
        "---",
        "third slide"
      })

      _G.input.usr_input = "0"

      mdp.goto_slide()

      assert.is.Nil(_G.sc.cmd)
      assert.is.Nil(_G.sc.args)
      eq("0 is not a valid slide number", _G.notify.str)
    end)

    it('does not call the server and notifies the user in case the inserted slide number is not a number', function()
      _G.input.usr_input = "xx"

      mdp.goto_slide()

      assert.is.Nil(_G.sc.cmd)
      assert.is.Nil(_G.sc.args)
      eq("xx is not a valid slide number", _G.notify.str)
    end)
  end)


  describe('live_sync option:', function()
    it('if on live_sync will be enabled on marp files', function()
      -- setup
      mdp.setup({ live_sync = true })
      server.is_running = function() return true end

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
      mdp.setup({ live_sync = false })

      setup_marp_file()

      assert.is.False(mdp.is_live_sync_on())

      mdp.toggle_live_sync()

      assert.is.True(mdp.is_live_sync_on())
      assert.is.True(goto_current_slide_called)

      mdp.goto_current_slide = original_goto_current_slide
    end)

    it('toggles live_sync off', function()
      -- Ensure live_sync is on initially
      mdp.setup({ live_sync = true })

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

      local original_current_slide_number = utils.current_slide_number
      utils.current_slide_number = function()
        return 5
      end

      mdp.goto_current_slide()

      eq(5, goto_slide_called_with)

      mdp._goto_slide = original_goto_slide
      utils.current_slide_number = original_current_slide_number
    end)

    it('does not call _goto_slide if the slide number is the same as the last one', function()
      local goto_slide_called = false
      local original_goto_slide = mdp._goto_slide
      mdp._goto_slide = function(slide_number)
        goto_slide_called = true
      end

      local original_current_slide_number = utils.current_slide_number
      utils.current_slide_number = function()
        return 5
      end

      mdp.goto_current_slide()

      assert.is.False(goto_slide_called)

      mdp._goto_slide = original_goto_slide
      utils.current_slide_number = original_current_slide_number
    end)
  end)
end)
