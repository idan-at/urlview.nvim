local M = {}

local utils = require("urlview.utils")
local config = require("urlview.config")

--- Use command to open the URL
---@param cmd string @name of executable to run
---@param args string|table @arg(s) to pass into cmd (unescaped URL string or table of args)
local function shell_exec(cmd, args)
  if cmd and vim.fn.executable(cmd) == 1 then
    -- NOTE: `vim.fn.system` shellescapes arguments
    local cmd_args = { cmd }
    vim.list_extend(cmd_args, type(args) == "table" and args or { args })
    local err = vim.fn.system(cmd_args)
    if vim.v.shell_error ~= 0 or err ~= "" then
      utils.log(
        string.format("Failed to navigate link with cmd `%s` and args `%s`\n%s", cmd, args, err),
        vim.log.levels.ERROR
      )
    end
  else
    utils.log(
      string.format("Cannot use command `%s` to navigate links (either empty or non-executable)", cmd),
      vim.log.levels.ERROR
    )
  end
end

--- Use `netrw` to navigate to a URL
---@param raw_url string @unescaped URL
function M.netrw(raw_url)
  local url = vim.fn.shellescape(raw_url)
  local ok, err = pcall(vim.cmd, string.format("call netrw#BrowseX(%s, netrw#CheckIfRemote(%s))", url, url))
  if not ok and vim.startswith(err, "Vim(call):E117: Unknown function") then
    -- lazily use system action if netrw is disabled
    M.system(raw_url)
  end
end

--- Use the user's default browser to navigate to a URL
---@param raw_url string @unescaped URL
function M.system(raw_url)
  local os = utils.os
  if os == "Darwin" then -- MacOS
    shell_exec("open", raw_url)
  elseif os == "Linux" or os == "FreeBSD" then -- Linux and FreeBSD
    shell_exec("xdg-open", raw_url)
  elseif os:match("Windows") then -- Windows
    -- HACK: `start` cmd itself doesn't exist but lives under `cmd`
    shell_exec("cmd", { "/C", "start", raw_url })
  else
    utils.log(
      "Unsupported operating system for `system` action. Please raise a GitHub issue for " .. os,
      vim.log.levels.WARN
    )
  end
end

--- Copy URL to clipboard
---@param raw_url string @unescaped URL
function M.clipboard(raw_url)
  vim.fn.setreg(config.default_register, raw_url)
  utils.log(string.format("URL %s copied to clipboard", raw_url), vim.log.levels.INFO)
end

--- Jump to the URL in the current buffer
---@param raw_url string @unescaped URL
function M.jump(raw_url)
  local bufnr = 0 -- current buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local prefix = config.default_prefix
  local url_without_prefix = raw_url
  if vim.startswith(raw_url, prefix) then
    url_without_prefix = raw_url:sub(#prefix + 1)
  end

  for line_idx, line in ipairs(lines) do
    -- Try matching the exact URL first
    local start, _ = line:find(raw_url, 1, true)
    if not start and url_without_prefix ~= raw_url then
      -- Try matching without the prefix
      start, _ = line:find(url_without_prefix, 1, true)
    end

    if start then
      vim.cmd("normal! m'") -- add to jump list
      vim.api.nvim_win_set_cursor(0, { line_idx, start - 1 })
      return
    end
  end
  utils.log(string.format("Could not find URL %s in buffer", raw_url), vim.log.levels.WARN)
end

return setmetatable(M, {
  -- execute action as command if it is not one of the above module keys
  __index = function(_, k)
    if k ~= nil then
      return function(raw_url)
        return shell_exec(k, raw_url)
      end
    end
  end,
})
