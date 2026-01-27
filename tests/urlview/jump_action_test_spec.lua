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
    vim.api.nvim_win_set_cursor(0, {1, 0})
    config.default_prefix = "https://"
  end)

  it("jumps to exact link", function()
    actions.jump("https://google.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({2, 16}, cursor)
  end)

  it("jumps to link without prefix", function()
    -- picker shows https://www.example.com but buffer has www.example.com
    actions.jump("https://www.example.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({4, 14}, cursor)
  end)

  it("does not jump if link not found", function()
    vim.api.nvim_win_set_cursor(0, {1, 0})
    actions.jump("https://notfound.com")
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.same({1, 0}, cursor)
  end)
end)
