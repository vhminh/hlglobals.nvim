local Query = require('hlglobals.query')

local M = {}

local ns = vim.api.nvim_create_namespace('hlglobals')

local function empty_iter()
  return nil
end

-- Use treesitter and lsp semantic token to find variables in the buffer
---@param bufnr number
---@return (fun(): TSNode)
local find_variables = function(bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local lang = assert(vim.treesitter.language.get_lang(filetype))
  local query = vim.treesitter.query.get(lang, 'variable')
  if query == nil then
    vim.notify_once(string.format('Unable to load "variable" query for %s', lang), vim.log.levels.ERROR)
    return empty_iter
  end
  local tree = vim.treesitter.get_parser(bufnr, lang):parse()[1]
  local node_iter = query:iter_matches(tree:root(), bufnr, 0, -1)
  local function iter()
    local _, match = node_iter()
    if match ~= nil then
      for id, node in pairs(match) do
        local name = query.captures[id]
        if name == 'variable' then
          -- treesitter Identifier node
          local row, col = node:start()
          local tokens = vim.lsp.semantic_tokens.get_at_pos(bufnr, row, col)
          if tokens ~= nil and #tokens >= 1 then
            local type = tokens[1].type
            if type == 'variable' then
              -- lsp variable semantic token
              return node
            end
          end
        end
      end
      return iter()
    end
  end
  return iter
end

---@param node TSNode current node
---@return TSNode? result previous sibling or parent if there isn't one
local function prev_sibling_or_parent(node)
  if not node then
    return nil
  end
  local prev = node:prev_named_sibling()
  if prev == nil then
    return node:parent()
  end
  return prev
end

local function extract_var_declarations_in_func(bufnr, fn_node)
  local vars_declared = {}
  local query = Query.new(bufnr, 'declaration')
  for stmt_node in query.iter(fn_node, 'statement') do
    for var_name_node in query.iter(stmt_node, 'name') do
      local var_name = vim.treesitter.get_node_text(var_name_node, bufnr)
      vars_declared[stmt_node:id()] = vars_declared[stmt_node:id()] or {}
      vim.list_extend(vars_declared[stmt_node:id()], { var_name })
    end
  end
  return vars_declared
end

---@param node TSNode
---@return boolean
local function is_function(node)
  return node:type() == 'function_declaration'
end

---@param node TSNode
---@return TSNode? fn_node node of the function containing this `node`
local function get_enclosing_function(node)
  local parent = node
  while parent and not is_function(parent) do
    parent = parent:parent()
  end
  return parent
end

-- Check if a variable is declared in function scope
---@param bufnr number buffer number
---@param node TSNode the node of type Identifier representing the variable
---@return boolean
local function is_declared_in_fn_scope(bufnr, node)
  ---@type TSNode?
  local fn = get_enclosing_function(node)
  if not fn then
    return false
  end
  local vars_declared = extract_var_declarations_in_func(bufnr, fn)
  local node_text = vim.treesitter.get_node_text(node, bufnr)
  ---@type TSNode?
  local prev = node
  while prev and prev:id() ~= fn:id() do
    if vim.tbl_contains(vars_declared[prev:id()] or {}, node_text) then
      return true
    end
    prev = prev_sibling_or_parent(prev)
  end
  return false
end

---@param bufnr number
---@param node TSNode
local function hl_node(bufnr, node)
  local start_row, start_col = node:start()
  local end_row, end_col = node:end_()
  vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
    hl_group = M.opts.hl_group,
    end_row = end_row,
    end_col = end_col,
    priority = vim.highlight.priorities.user,
    strict = false,
  })
end

---@param bufnr number
local function hl_buf(bufnr)
  for var_node in find_variables(bufnr) do
    if not is_declared_in_fn_scope(bufnr, var_node) then
      hl_node(bufnr, var_node)
    end
  end
end

local function clear_hl_buf(bufnr)
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
  for _, mark in ipairs(marks) do
    vim.api.nvim_buf_del_extmark(bufnr, ns, mark[1])
  end
end

M.default_opts = {
  enabled = false,
  hl_group = 'ErrorMsg',
}

local setup_called = false

local function ensure_setup()
  M.setup(M.default_opts)
end

---@param opts any
function M.setup(opts)
  if setup_called then
    return
  end
  setup_called = true
  M.opts = vim.tbl_deep_extend('force', M.default_opts, opts)
  if M.opts.enabled then
    M.enable()
  else
    M.disable()
  end
end

---@param bufnr number?
function M.enable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  M.opts.enabled = true
  hl_buf(bufnr)
end

---@param bufnr number?
function M.disable(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  M.opts.enabled = false
  clear_hl_buf(bufnr)
end

function M.toggle(bufnr)
  ensure_setup()
  bufnr = bufnr or vim.fn.bufnr()
  if M.opts.enabled then
    M.disable(bufnr)
  else
    M.enable(bufnr)
  end
end

return M
