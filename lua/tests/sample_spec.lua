local Job = require('plenary.job')
local Path = require('plenary.path')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local hlglobals = require('hlglobals')
local utils = require('tests.utils')
local mock_server = require('tests/lsp_server').mock_server

local ns = vim.api.nvim_create_namespace('hlglobals')
local resource_path = 'lua/tests/resource'

-- First level directories in the resource folder are language names
---@return table<string>
local function extract_languages()
  local finder = Job:new({
    command = 'find',
    args = { resource_path, '-type', 'd', '-maxdepth', '1' },
  })
  local paths = vim.tbl_map(Path.new, finder:sync())
  local tails = vim.tbl_map(function(path)
    return Path:new(path):make_relative(resource_path)
  end, paths)
  return vim.tbl_filter(function(tail)
    return tail ~= '.'
  end, tails)
end

-- Every file in resource/{lang} are samples for that language
---@param lang string
---@return table<string>
local function extract_sample_files(lang)
  local lang_res_path = Path:new(resource_path, lang):absolute()
  local finder = Job:new({
    command = 'find',
    args = { lang_res_path, '-type', 'f' },
  })
  local paths = vim.tbl_map(Path.new, finder:sync())
  local relatives = vim.tbl_map(function(path)
    return Path:new(path):make_relative(lang_res_path)
  end, paths)
  return relatives
end

---@param languages table<string>
local function setup_treesitter(languages)
  require('nvim-treesitter.configs').setup({
    ensure_installed = languages,
    sync_install = true,
  })
  require('nvim-treesitter.install').ensure_installed_sync()
end

-- Mock a lsp client with these predefined semantic tokens
---@param var_positions table<TokenPos> positions of variable token
---@return number|nil client_id
local mock_lsp_client = function(var_positions)
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local config = {
    cmd = mock_server(var_positions),
    capabilities = capabilities,
  }
  return vim.lsp.start(config)
end

-- Return a token length on a `line` starting at `start`
---@param line string
---@param start integer 0-indexed
---@return integer token_length
local function token_length(line, start)
  local count = 0
  while start + count <= #line and utils.is_alpha_numeric(string.sub(line, start + count + 1, start + count + 1)) do
    count = count + 1
  end
  return count
end

-- Extract variable from sample source code
-- Each variable token is indicated by `^^` in the next row
---@param lines table<table<string>> source code as lines
---@return table<TokenPos> variable_positions list of 0-indexed [[line, col]]
local function extract_variable(lines)
  local vars = {}
  for i = 1, #lines do
    local line = lines[i]
    local indices = utils.gfind(line, '^^', true)
    for _, index in ipairs(indices) do
      vars[#vars + 1] = {
        line = i - 2, -- `^^` is 1 line below the actual variable
        col = index - 1,
        length = token_length(lines[i - 1], index - 1),
      }
    end
  end
  return vars
end

-- Extract expected global var from sample source code that needs to be highlighted
-- Each expected global variable is indicated by `^^here` in the next row
---@param lines table<table<string>> source code as lines
---@return table<TokenPos> positions list of 0-indexed [[line, col]]
local function extract_expected_globals(lines)
  local vars = {}
  for i = 1, #lines do
    local line = lines[i]
    local indices = utils.gfind(line, '^^here', true)
    for _, index in ipairs(indices) do
      vars[#vars + 1] = {
        line = i - 2, -- `^^here` is 1 line below the actual global var
        col = index - 1,
        length = token_length(lines[i - 1], index - 1),
      }
    end
  end
  return vars
end

local languages = extract_languages()
setup_treesitter(languages)

---@param lang string
local function setup_tests(lang)
  describe(lang, function()
    for _, test_file in ipairs(extract_sample_files(lang)) do
      it(test_file, function()
        -- read test file
        local path = Path.new(resource_path, lang, test_file)
        local content = path:read()
        local lines = vim.split(content, '\n')

        -- create empty buffer
        local bufnr = assert(vim.api.nvim_create_buf(true, true))
        vim.api.nvim_buf_set_option(bufnr, 'filetype', lang)

        -- attach lsp client to buffer
        local client_id = assert(mock_lsp_client(extract_variable(lines)))
        vim.lsp.buf_attach_client(bufnr, client_id)
        vim.lsp.semantic_tokens.start(bufnr, client_id)

        -- insert file content
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

        -- highlight
        vim.wait(6)
        hlglobals.enable(bufnr)

        -- assertions
        local expected_globals = vim.tbl_map(function(token_pos)
          return {
            line = token_pos.line,
            col = token_pos.col,
          }
        end, extract_expected_globals(lines))
        local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
        local highlighted = {}
        for _, mark in ipairs(marks) do
          highlighted[#highlighted + 1] = {
            line = mark[2],
            col = mark[3],
          }
        end
        assert.are.same(expected_globals, highlighted)

        -- stop lsp client
        vim.lsp.stop_client(client_id)
      end)
    end
  end)
end

for _, lang in ipairs(languages) do
  setup_tests(lang)
end
