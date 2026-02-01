local actions = require("urlview.actions")
local config = require("urlview.config")

describe("jump action", function()
  before_each(function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "line 1",
      "here is a link: https://google.com",
      "line 3",
      "another link: www.example.com",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    config.default_prefix = "https://"
  end)

  it("jumps to exact link", function()
    actions.jump("https://google.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({ 2, 16 }, cursor)
  end)

  it("jumps to link without prefix", function()
    -- picker shows https://www.example.com but buffer has www.example.com
    actions.jump("https://www.example.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({ 4, 14 }, cursor)
  end)

  it("does not jump if link not found", function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    actions.jump("https://notfound.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({ 1, 0 }, cursor)
  end)

  it("populates jumplist and jumps to first occurrence of multiple links", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "line 1",
      "first: https://google.com",
      "second: google.com",
      "third: http://google.com",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    actions.jump("https://google.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    -- Should jump to first match: "first: https://google.com" -> line 2, col 7 (0-based)
    assert.same({ 2, 7 }, cursor)
  end)

  it("works backwards to find full URL from partial match", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "text: https://sub.domain.com/path",
    })

    actions.jump("https://sub.domain.com/path")
    local cursor = vim.api.nvim_win_get_cursor(0)
    -- Should be start of https:// -> col 6.
    assert.same({ 1, 6 }, cursor)
  end)
end)

