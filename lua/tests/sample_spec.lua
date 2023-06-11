local Job = require('plenary.job')
local Path = require('plenary.path')
local describe = require('plenary.busted').describe
local it = require('plenary.busted').it

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

local languages = extract_languages()

for _, lang in ipairs(languages) do
  describe(lang, function()
    for _, test_file in ipairs(extract_sample_files(lang)) do
      it(test_file, function()
        local content = Path.new(resource_path, lang, test_file):read()
        print(vim.inspect(content))
        assert.are.equal(1, 1)
      end)
    end
  end)
end
