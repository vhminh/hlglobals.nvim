local Query = require('hlglobals.query')

---@class Highlighter
---@field bufnr number
---@field filetype string
---@field lang string
---@field hl_buf fun()
---@field clear_hl_buf fun()
---@field detach fun() the function to be called when the highlighter detaches from buffer
local Highlighter = {}

local ns = vim.api.nvim_create_namespace('hlglobals')

---@generic K, V
---@param cache any
---@param key K
---@param callback fun(key: K): V
---@return V
local function with_cache(cache, key, callback)
  if cache[key] ~= nil then
    return cache[key]
  end
  local value = callback(key)
  cache[key] = value
  return value
end

-- Create a highlighter and attach to the buffer
---@param bufnr number
---@return Highlighter
function Highlighter.new(bufnr, opts)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local lang = assert(vim.treesitter.language.get_lang(filetype))
  local self = {
    bufnr = bufnr,
    filetype = filetype,
    lang = lang,
  }
  local var_query = Query.new(bufnr, 'variable')
  local decl_query = Query.new(bufnr, 'declaration')

  local var_decl_by_fn = {}
  local function clear_cache()
    var_decl_by_fn = {}
  end

  -- Check if the given identifier node is a variable
  -- TODO: language specific function, need refactoring
  ---@param ident_node TSNode
  ---@return boolean
  local function is_var_node(ident_node)
    local function check_lsp_semantic_token(node)
      local row, col = node:start()
      local tokens = vim.lsp.semantic_tokens.get_at_pos(bufnr, row, col)
      if tokens ~= nil and #tokens >= 1 then
        local type = tokens[1].type
        if type == 'variable' then
          return true
        end
      end
      return false
    end
    ---@param node TSNode
    local function is_keyed_element(node)
      local parent = node:parent()
      if not parent then
        return false
      end
      local grandparent = parent:parent()
      if not grandparent then
        return false
      end
      local is_first_keyed_element = grandparent:named_children()[1]:id() == parent:id()
      return is_first_keyed_element and parent:type() == 'literal_element' and grandparent:type() == 'keyed_element'
    end
    return check_lsp_semantic_token(ident_node) and not is_keyed_element(ident_node)
  end

  -- Use treesitter and lsp semantic token to find variables in the buffer
  ---@return (fun(): TSNode)
  function self.find_variables()
    local tree = vim.treesitter.get_parser(bufnr, self.lang):parse()[1]
    local ident_iter = var_query.iter(tree:root(), 'ident')

    local function iter()
      local ident_node = ident_iter()
      if ident_node == nil then
        return nil
      end
      if not is_var_node(ident_node) then
        return iter()
      end
      return ident_node
    end

    return iter
  end

  -- Check if a variable is declared in function scope
  ---@param node TSNode the node of type Identifier representing the variable
  ---@return boolean
  function self.is_declared_in_fn_scope(node)
    ---@type TSNode?
    local fn = self.get_enclosing_function(node)
    if not fn then
      return false
    end
    local vars_declared = with_cache(var_decl_by_fn, fn:id(), function()
      return self.extract_var_declarations_in_func(fn)
    end)
    local node_text = vim.treesitter.get_node_text(node, bufnr)
    ---@type TSNode?
    local prev = node
    while prev and prev:id() ~= fn:id() do
      if vim.tbl_contains(vars_declared[prev:id()] or {}, node_text) then
        return true
      end
      prev = self.prev_sibling_or_parent(prev)
    end
    return false
  end

  ---@param node TSNode current node
  ---@return TSNode? result previous sibling or parent if there isn't one
  function self.prev_sibling_or_parent(node)
    if not node then
      return nil
    end
    local prev = node:prev_named_sibling()
    if prev == nil then
      return node:parent()
    end
    return prev
  end

  ---@param fn_node TSNode
  ---@return table<string, table<string>> var_names_declared_in_stmt a mapping from var declaration statement (TSNode id)
  --  to a list of variable names that are declared within that statement
  function self.extract_var_declarations_in_func(fn_node)
    local vars_declared = {}
    for stmt_node in decl_query.iter(fn_node, 'statement') do
      for var_name_node in decl_query.iter(stmt_node, 'name') do
        local var_name = vim.treesitter.get_node_text(var_name_node, bufnr)
        vars_declared[stmt_node:id()] = vars_declared[stmt_node:id()] or {}
        vim.list_extend(vars_declared[stmt_node:id()], { var_name })
      end
    end
    return vars_declared
  end

  -- TODO: language specific function, need refactoring
  ---@param node TSNode
  ---@return boolean
  local function is_function(node)
    return vim.tbl_contains({ 'function_declaration', 'method_declaration', 'func_literal' }, node:type())
  end

  ---@param node TSNode
  ---@return TSNode? fn_node node of the function containing this `node`
  function self.get_enclosing_function(node)
    local parent = node
    while parent and not is_function(parent) do
      parent = parent:parent()
    end
    return parent
  end

  function self.hl_buf()
    self.clear_hl_buf()
    for var_node in self.find_variables() do
      if not self.is_declared_in_fn_scope(var_node) then
        self.hl_node(var_node)
      end
    end
  end

  ---@param node TSNode
  function self.hl_node(node)
    local start_row, start_col = node:start()
    local end_row, end_col = node:end_()
    vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
      hl_group = opts.hl_group,
      end_row = end_row,
      end_col = end_col,
      priority = vim.highlight.priorities.user,
      strict = false,
    })
  end

  function self.clear_hl_buf()
    clear_cache()
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark[1])
    end
  end

  function self.detach()
    self.clear_hl_buf()
  end

  return self
end

return Highlighter
