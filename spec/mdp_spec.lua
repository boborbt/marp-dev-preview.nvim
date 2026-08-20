local mdp = require("marp-dev-preview")
local utils = require("marp-dev-preview.utils")
local server = require("marp-dev-preview.server")
local eq = assert.are.same

describe("marp-dev-preview methods:", function()
  -- Mocking various objects. _G will contain the parameters and the
  -- return values of the mocked functions
  local _G = {
    -- server_cmd
    sc = {
      cmd = nil,
      args = nil,
      ok = true,
      response = { body = "success" },
    },

    -- vim.notify
    notify = {
      orig = vim.notify,
      str = nil,
    },

    -- vim.fn.input
    input = {
      orig = vim.fn.input,
      usr_input = nil,
    },
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
    os.remove("test.md")
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

    vim.bo.filetype = "markdown"
  end

  function setup_md_file()
    -- create a marp file
    local file = io.open("test.md", "w")
    file:write("# Some markdown file \ncontaining some *md* code\non multiple lines")
    file:close()

    vim.cmd("edit test.md")
  end

  describe("config functions", function()
    it("setup can be correctly accessed", function()
      mdp.setup({
        auto_sync = true,
        port = 9898,
        time_out = 42,
      })

      assert.is.True(mdp.get("auto_sync"))
      eq(9898, mdp.get("port"))
      eq(42, mdp.get("time_out"))
    end)

    it("get returns nil for non-existing keys", function()
      assert.is.Nil(mdp.get("non_existing_key"))
    end)

    it("get returns the value set via set", function()
      mdp.set("auto_sync", "bullshit value")
      eq("bullshit value", mdp.get("auto_sync"))
    end)
  end)

  describe("is_marp", function()
    it("returns false on non-markdown non-marp files", function()
      vim.cmd("enew")

      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "hello",
        "world",
      })

      assert.is.False(utils.is_marp())
    end)

    it("returns false on markdown non-marp files", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")

      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "hello",
        "world",
      })

      assert.is.False(utils.is_marp())
    end)

    it("returns false on non-markdown marp files", function()
      -- Create a new empty buffer
      vim.cmd("enew")

      -- Insert some lines
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
      })

      assert.is.False(utils.is_marp())
    end)

    it("returns true on marp with style code", function()
      str = table.concat({
        "---\n",
        "marp: true\n",
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
        "}\n",
      })

      setup_marp_file(str)

      assert.is.True(utils.is_marp())
    end)

    it("returns true on markdown marp files", function()
      setup_marp_file()

      assert.is.True(utils.is_marp())
    end)
  end)

  describe("num_slides", function()
    it("returns the total number of slides", function()
      setup_marp_file("---\nmarp: true\n---\nfirst slide\n---\nsecond slide\n---\nthird slide")
      local n = utils.num_slides()
      eq(3, n)
    end)
    it("does not get confused if a line starts with --- but contains other stuff", function()
      setup_marp_file("---\nmarp: true\n---\nfirst slide\n--- some other stuff\n---\nsecond slide\n---\nthird slide")
      local n = utils.num_slides()
      eq(3, n)
    end)
  end)

  describe("current_slide_number", function()
    it("returns -1 on empty file", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")

      eq(utils.current_slide_number(), -1)
    end)

    it("returns 0 when cursor is before the first slide", function()
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
        "third slide",
      })
      vim.cmd("1")

      eq(0, utils.current_slide_number())
    end)

    it("returns the corret slide number when cursor is in the middle of the file", function()
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
        "third slide",
      })
      vim.cmd("6")

      eq(2, utils.current_slide_number())
    end)

    it("returns the number of last slide when cursor is at the end of the file", function()
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
        "third slide",
      })
      vim.cmd("8")

      eq(3, utils.current_slide_number())
    end)

    it("does not get confused if a line starts with --- but contains other stuff", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "--- some other stuff",
        "still first slide",
        "---",
        "second slide",
        "---",
        "third slide",
      })
      vim.cmd("7")

      eq(2, utils.current_slide_number())
    end)
  end)

  describe("goto_slide", function()
    it("it reposition the cursor within the selected slide (success case)", function()
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
        "third slide",
      })

      _G.input.usr_input = "2"

      mdp.goto_slide()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it(
      "does not call the server and notifies the user in case the inserted slide number is >= than the total number of slides",
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
          "third slide",
        })

        _G.input.usr_input = "4"

        mdp.goto_slide()

        assert.is.Nil(_G.sc.cmd)
        assert.is.Nil(_G.sc.args)
        eq("4 is not a valid slide number", _G.notify.str)
      end
    )

    it("does not call the server and notifies the user in case the inserted slide number is <=0", function()
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
        "third slide",
      })

      _G.input.usr_input = "0"

      mdp.goto_slide()

      assert.is.Nil(_G.sc.cmd)
      assert.is.Nil(_G.sc.args)
      eq("0 is not a valid slide number", _G.notify.str)
    end)

    it("does not call the server and notifies the user in case the inserted slide number is not a number", function()
      _G.input.usr_input = "xx"

      mdp.goto_slide()

      assert.is.Nil(_G.sc.cmd)
      assert.is.Nil(_G.sc.args)
      eq("xx is not a valid slide number", _G.notify.str)
    end)
  end)

  describe("slide navigation", function()
    it("next_slide moves to the first content line of the next slide", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "---",
        "second slide",
        "still second slide",
        "---",
        "third slide",
      })
      vim.cmd("4")

      mdp.next_slide()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("prev_slide moves to the first content line of the previous slide", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "first slide",
        "---",
        "second slide",
        "still second slide",
        "---",
        "third slide",
      })
      vim.cmd("9")

      mdp.prev_slide()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("maps normal ]S and [S to slide movement on marp buffers", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\nfirst slide\n---\nsecond slide\n---\nthird slide\n")
      vim.cmd("4")

      local next_map = vim.fn.maparg("]S", "n", false, true)
      local prev_map = vim.fn.maparg("[S", "n", false, true)

      assert.is_not.Nil(next_map.callback)
      assert.is_not.Nil(prev_map.callback)

      next_map.callback()
      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))

      vim.cmd("8")
      prev_map.callback()
      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe("slide text objects", function()
    it("maps visual iS to slide selection on marp buffers", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\nfirst slide\n---\nsecond slide\n")
      vim.cmd("4")

      local map = vim.fn.maparg("iS", "x", false, true)

      assert.is_not.Nil(map.callback)
      map.callback()
      eq({ 4, 0 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe("box text objects", function()
    it("selects the inner content of the current ::: container", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "before",
        "::: warn",
        "box content",
        "more box content",
        ":::",
        "after",
      })
      vim.cmd("6")

      mdp.select_box(false)

      eq({ 7, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("selects the current ::: container including delimiters", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "before",
        "::: warn",
        "box content",
        "more box content",
        ":::",
        "after",
      })
      vim.cmd("6")

      mdp.select_box(true)

      eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("viC selects the inner ::: container from visual mode", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\nbefore\n::: warn\nbox content\nmore box content\n:::\nafter\n")
      vim.cmd("6")

      vim.cmd("normal viC")

      eq("V", vim.fn.mode())
      eq(6, vim.fn.line("v"))
      eq({ 7, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("vaC selects the current ::: container including delimiters from visual mode", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\nbefore\n::: warn\nbox content\nmore box content\n:::\nafter\n")
      vim.cmd("6")

      vim.cmd("normal vaC")

      eq("V", vim.fn.mode())
      eq(5, vim.fn.line("v"))
      eq({ 8, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("maps visual iC to inner ::: container selection on marp buffers", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\n::: warn\nbox content\n:::\n")
      vim.cmd("5")

      local map = vim.fn.maparg("iC", "x", false, true)

      assert.is_not.Nil(map.callback)
      map.callback()
      eq({ 5, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("goto_next_box moves to the first line inside the next ::: container", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "before",
        "::: warn",
        "first box",
        ":::",
        "middle",
        "::: info",
        "second box",
        ":::",
      })
      vim.cmd("4")

      mdp.goto_next_box()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("goto_prev_box moves to the first line inside the previous ::: container", function()
      vim.cmd("enew")
      vim.cmd("set filetype=markdown")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "---",
        "marp:true",
        "---",
        "before",
        "::: warn",
        "first box",
        ":::",
        "middle",
        "::: info",
        "second box",
        ":::",
      })
      vim.cmd("10")

      mdp.goto_prev_box()

      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)

    it("maps normal ]C to next ::: container on marp buffers", function()
      mdp.setup({})
      setup_marp_file("---\nmarp:true\n---\nbefore\n::: warn\nbox content\n:::\n")
      vim.cmd("4")

      local map = vim.fn.maparg("]C", "n", false, true)

      assert.is_not.Nil(map.callback)
      map.callback()
      eq({ 6, 0 }, vim.api.nvim_win_get_cursor(0))
    end)
  end)

  describe("live_sync option:", function()
    it("if on live_sync will be enabled on marp files", function()
      -- setup
      mdp.setup({ live_sync = true })
      server.is_running = function()
        return true
      end

      setup_marp_file()

      assert.is.True(mdp.is_live_sync_on())
    end)
  end)

  it("debounces text changes before refreshing the server", function()
    local config = require("marp-dev-preview.config")
    local original_refresh_async = server.refresh_async
    local original_is_running = server.is_running
    local original_debounce = config.options.live_sync_debounce
    local refreshes = {}

    server.is_running = function()
      return true
    end
    server.refresh_async = function(markdown, callback)
      table.insert(refreshes, markdown)
      callback(true, {})
    end

    mdp.setup({ live_sync = true, live_sync_debounce = 1 })
    setup_marp_file()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", "marp:true", "---", "first" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", "marp:true", "---", "second" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })

    vim.wait(100, function()
      return #refreshes == 1
    end)

    eq(1, #refreshes)
    eq("---\nmarp:true\n---\nsecond", refreshes[1])

    server.refresh_async = original_refresh_async
    server.is_running = original_is_running
    config.options.live_sync_debounce = original_debounce
  end)

  it("coalesces overlapping refreshes and sends the latest pending markdown", function()
    local config = require("marp-dev-preview.config")
    local original_refresh_async = server.refresh_async
    local original_is_running = server.is_running
    local original_debounce = config.options.live_sync_debounce
    local refreshes = {}
    local callbacks = {}

    server.is_running = function()
      return true
    end
    server.refresh_async = function(markdown, callback)
      table.insert(refreshes, markdown)
      table.insert(callbacks, callback)
    end

    mdp.setup({ live_sync = true, live_sync_debounce = 1 })
    setup_marp_file()

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", "marp:true", "---", "first" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })

    vim.wait(100, function()
      return #refreshes == 1
    end)

    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", "marp:true", "---", "second" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })

    vim.wait(100, function()
      return #refreshes > 1
    end)

    eq(1, #refreshes)

    callbacks[1](true, {})

    vim.wait(100, function()
      return #refreshes == 2
    end)

    eq(2, #refreshes)
    eq("---\nmarp:true\n---\nsecond", refreshes[2])

    server.refresh_async = original_refresh_async
    server.is_running = original_is_running
    config.options.live_sync_debounce = original_debounce
  end)

  describe("toggle_live_sync", function()
    it("toggles live_sync on and calls goto_current_slide", function()
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

    it("toggles live_sync off", function()
      -- Ensure live_sync is on initially
      mdp.setup({ live_sync = true })

      mdp.toggle_live_sync()

      assert.is.False(mdp.is_live_sync_on())
    end)
  end)

  describe("goto_current_slide", function()
    it("calls server.goto_slide with the current slide number", function()
      local goto_slide_called_with = nil
      local original_goto_slide = server.goto_slide
      server.goto_slide = function(slide_number)
        goto_slide_called_with = slide_number
      end

      local original_current_slide_number = utils.current_slide_number
      utils.current_slide_number = function()
        return 5
      end

      mdp.goto_current_slide()

      eq(5, goto_slide_called_with)

      server.goto_slide = original_goto_slide
      utils.current_slide_number = original_current_slide_number
    end)

    it("does not call server.goto_slide if the slide number is the same as the last one", function()
      local goto_slide_called = false
      local original_goto_slide = server.goto_slide
      server.goto_slide = function(slide_number)
        goto_slide_called = true
      end

      local original_current_slide_number = utils.current_slide_number
      utils.current_slide_number = function()
        return 5
      end

      mdp.goto_current_slide()

      assert.is.False(goto_slide_called)

      server.goto_slide = original_goto_slide
      utils.current_slide_number = original_current_slide_number
    end)
  end)
end)
