local M = {}

-- Encode positions into a byte array
-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens
---@param positions table<TokenPos>
---@return table<integer> data
local function encode_token_positions(positions)
  local data = {}
  for _, pos in ipairs(positions) do
    local last_line = data[#data - 4] or 0
    local relative_line = pos.line - last_line
    local last_col = data[#data - 3] or 0
    local relative_col = relative_line == 0 and pos.col - last_col or pos.col
    vim.list_extend(data, {
      relative_line,
      relative_col,
      pos.length,
      0, -- token type
      0, -- token modifiers
    })
  end
  return data
end

---@param var_sem_tokens table<TokenPos> list of semantic tokens of type variable
function M.mock_server(var_sem_tokens)
  ---@param dispatchers table
  ---@return table
  return function(dispatchers)
    local closing = false
    local srv = {}

    ---@diagnostic disable-next-line: unused-local
    function srv.request(method, params, callback)
      if method == 'initialize' then
        local capabilities = {
          semanticTokensProvider = {
            full = true,
            legend = {
              tokenTypes = {
                'variable',
              },
              tokenModifiers = { 'private' },
            },
          },
        }
        callback(nil, { capabilities = capabilities })
      elseif method == 'shutdown' then
        callback(nil, nil)
      elseif method == 'textDocument/semanticTokens/full' then
        callback(nil, { data = encode_token_positions(var_sem_tokens) })
      end
      return true, 1
    end

    ---@diagnostic disable-next-line: unused-local
    function srv.notify(method, params)
      if method == 'exit' then
        dispatchers.on_exit(0, 15)
      end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end
end

return M
