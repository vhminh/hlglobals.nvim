local Job = require('plenary.job')
local Path = require('plenary.path')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it
local hlglobals = require('hlglobals')

local ns = vim.api.nvim_create_namespace('hlglobals')

local resource_path = 'lua/tests/resource'

-- First level directories in resource folder are language names
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

---@param _languages table<string>
local function setup_treesitter(_languages)
  require('nvim-treesitter.configs').setup({
    ensure_installed = _languages,
  })
end
require('nvim-treesitter.install').ensure_installed_sync()

local setup_lsp_client = (function()
  local client_by_lang = {}
  ---@param lang string
  return function(lang)
    if client_by_lang[lang] == nil then
      local co = coroutine.running()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local config = {
        name = 'gopls',
        cmd = { 'gopls' },
        root_dir = Path:new(vim.loop.cwd(), resource_path, lang):absolute(),
        capabilities = capabilities,
        on_init = function(client)
          print(vim.inspect(client.server_capabilities.semanticTokensProvider))
          if not client.server_capabilities.semanticTokensProvider then
            local semantic = client.config.capabilities.textDocument.semanticTokens
            client.server_capabilities.semanticTokensProvider = {
              full = true,
              legend = { tokenModifiers = semantic.tokenModifiers, tokenTypes = semantic.tokenTypes },
              range = true,
            }
          end
          assert(coroutine.resume(co, client))
        end,
        handlers = {},
        settings = {
          enableSemanticHighlighting = true,
          ['gopls'] = {
            semanticTokens = true,
          },
        },
      }

      local function lookup_section(settings, section)
        for part in vim.gsplit(section, '.', true) do
          settings = settings[part]
          if not settings then
            return
          end
        end
        return settings
      end

      config.handlers['workspace/configuration'] = function(err, method, params, client_id)
        if err then
          error(tostring(err))
        end
        if not params.items then
          return {}
        end

        local result = {}
        for _, item in ipairs(params.items) do
          if item.section then
            local value = lookup_section(config.settings, item.section) or vim.NIL
            -- For empty sections with no explicit '' key, return settings as is
            if value == vim.NIL and item.section == '' then
              value = config.settings or vim.NIL
            end
            table.insert(result, value)
          end
        end
        return result
      end

      client_by_lang[lang] = vim.lsp.start(config)
      local client = coroutine.yield()
      client_by_lang[lang] = client
    end
    return client_by_lang[lang]
  end
end)()

local languages = extract_languages()
setup_treesitter(languages)

---@param lang string
local function setup_tests(lang)
  local client = setup_lsp_client(lang)
  -- vim.wait(1000)
  -- local bufnr = vim.api.nvim_create_buf(true, true)
  -- assert(bufnr ~= 0)
  -- vim.api.nvim_buf_set_option(bufnr, 'filetype', lang)
  -- -- vim.api.nvim_buf_set_option(bufnr, 'readonly', true)
  -- vim.lsp.buf_attach_client(bufnr, assert(client.id))
  describe(lang, function()
    for _, test_file in ipairs(extract_sample_files(lang)) do
      it(test_file, function()
        -- read test file
        local path = Path.new(resource_path, lang, test_file)
        local content = path:read()
        local lines = vim.split(content, '\n')

        -- create a new buffer with correct filetype and insert the file content
        local bufnr = vim.api.nvim_create_buf(true, true)
        assert(bufnr ~= 0)
        vim.api.nvim_buf_set_option(bufnr, 'filetype', lang)
        vim.api.nvim_buf_set_option(bufnr, 'readonly', true)
        --vim.api.nvim_buf_set_name(bufnr, path:absolute())
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)

        vim.wait(100)
        -- attach lsp client to buffer
        vim.lsp.buf_attach_client(bufnr, assert(client.id))
        vim.wait(100)
        vim.lsp.semantic_tokens.force_refresh(bufnr)

        print(vim.inspect(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)))

        vim.wait(1000)
        -- highlight
        hlglobals.enable(bufnr)

        -- assertions
        local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {})
        print(vim.inspect(marks))
        -- for _, mark in ipairs(marks) do
        --   print(mark)
        --   vim.api.nvim_buf_del_extmark(bufnr, ns, mark[1])
        -- end
        assert.are.equal(1, 1)
      end)
    end
  end)
end

for _, lang in ipairs(languages) do
  setup_tests(lang)
end
