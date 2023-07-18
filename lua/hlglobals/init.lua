local Highlighter = require('hlglobals.highlighter')
local Opts = require('hlglobals.opts')
local throttle = require('hlglobals.throttle')

local M = {}

---@type table<integer,Highlighter>
local highlighters = {}
---@type table<integer,boolean>
local enable = {}

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
function M.is_enabled(bufnr)
  ensure_setup()
  if enable[bufnr] ~= nil then
    return enable[bufnr]
  end
  return assert(M.opts).enabled
end

---@param bufnr number?
function M.enable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  enable[bufnr] = true
  hl_buf(bufnr)
end

---@param bufnr number?
function M.disable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  enable[bufnr] = false
  clear_hl_buf(bufnr)
end

---@param bufnr number?
function M.toggle(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  if M.is_enabled(bufnr) then
    M.disable(bufnr)
  else
    M.enable(bufnr)
  end
end

---@param bufnr number
local function update_hightlighter(bufnr)
  local current_highlighter = highlighters[bufnr]
  if current_highlighter == nil then
    return
  end
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if current_highlighter.filetype == filetype then
    return
  end
  current_highlighter.detach()
  highlighters[bufnr] = Highlighter.new(bufnr)
end

---@param bufnr number
M.update = throttle(function(bufnr)
  ensure_setup()
  update_hightlighter(bufnr)
  if M.is_enabled(bufnr) then
    hl_buf(bufnr)
  else
    clear_hl_buf(bufnr)
  end
end)

return M
