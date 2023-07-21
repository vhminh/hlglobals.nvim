local Highlighter = require('hlglobals.highlighter')
local Opts = require('hlglobals.opts')

local M = {}

---@type table<integer,Highlighter>
local highlighters = {}
---@type table<integer,boolean>
local enable = {}

local supported_filetypes = { 'go' }

---@type Opts?
M.opts = nil

local function hl_buf(bufnr)
  if highlighters[bufnr] == nil then
    highlighters[bufnr] = Highlighter.new(bufnr, M.opts)
  end
  local highlighter = highlighters[bufnr]
  highlighter.hl_buf()
end

local function clear_hl_buf(bufnr)
  if highlighters[bufnr] ~= nil then
    local highlighter = highlighters[bufnr]
    highlighter.clear_hl_buf()
  end
end

local function ensure_setup()
  if M.opts == nil then
    M.setup()
  end
end

---@param user_opts any
function M.setup(user_opts)
  M.opts = Opts.merge(user_opts or {})
end

---@param bufnr integer
function M.is_plugin_enabled(bufnr)
  ensure_setup()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  return vim.tbl_contains(supported_filetypes, filetype) and assert(M.opts).enabled
end

---@param bufnr integer
function M.is_hl_enabled(bufnr)
  ensure_setup()
  if enable[bufnr] ~= nil then
    return enable[bufnr]
  end
  return M.is_plugin_enabled(bufnr)
end

---@param bufnr number?
function M.enable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  if M.is_plugin_enabled(bufnr) then
    enable[bufnr] = true
    hl_buf(bufnr)
  end
end

---@param bufnr number?
function M.disable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  if M.is_plugin_enabled(bufnr) then
    enable[bufnr] = false
    clear_hl_buf(bufnr)
  end
end

---@param bufnr number?
function M.toggle(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  if not M.is_plugin_enabled(bufnr) then
    return
  end
  if M.is_hl_enabled(bufnr) then
    M.disable(bufnr)
  else
    M.enable(bufnr)
  end
end

---@param bufnr number
local function replace_outdated_highlighter(bufnr)
  local current_highlighter = highlighters[bufnr]
  if current_highlighter == nil then
    return
  end
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if current_highlighter.filetype == filetype then
    return
  end
  current_highlighter.detach()
  if not M.is_plugin_enabled(bufnr) then
    return
  end
  highlighters[bufnr] = Highlighter.new(bufnr)
end

---@param bufnr number
function M.update(bufnr)
  ensure_setup()
  replace_outdated_highlighter(bufnr)
  if M.is_plugin_enabled(bufnr) then
    if M.is_hl_enabled(bufnr) then
      hl_buf(bufnr)
    else
      clear_hl_buf(bufnr)
    end
  end
end

local timer = assert(vim.loop.new_timer())
timer:start(0, 200, function()
  vim.schedule(function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      if vim.tbl_contains(supported_filetypes, filetype) then
        M.update(bufnr)
      end
    end
  end)
end)

return M
