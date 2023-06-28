local Query = {}

function Query.new(bufnr, name)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local lang = assert(vim.treesitter.language.get_lang(filetype))
  local query = assert(vim.treesitter.query.get(lang, name))

  local self = {
    lang = lang,
    bufnr = bufnr,
  }

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
