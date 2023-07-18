---@class Query
---@field bufnr integer
---@field filetype string
---@field lang string
---@field iter fun(root: TSNode, capture_name: string, start: integer|nil, stop: integer|nil): (fun(): TSNode|nil)
local Query = {}

---@param bufnr number
---@param name string name of the query to load
---@return Query
function Query.new(bufnr, name)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local lang = assert(vim.treesitter.language.get_lang(filetype))
  local query = assert(vim.treesitter.query.get(lang, name))

  local self = {
    bufnr = bufnr,
    filetype = filetype,
    lang = lang,
  }

  ---@param root TSNode
  ---@param capture_name string
  ---@param start integer|nil
  ---@param stop integer|nil
  ---@return fun(): TSNode|nil
  function self.iter(root, capture_name, start, stop)
    start = start or 0
    stop = stop or -1
    local capture_iter = query:iter_captures(root, bufnr, start, stop)
    local function iter()
      local id, node, _ = capture_iter()
      if not id then
        return nil
      end
      local captured_name = query.captures[id]
      if captured_name == capture_name then
        return node
      end
      return iter()
    end
    return iter
  end

  return self
end

return Query
