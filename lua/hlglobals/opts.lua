---@class Opts
---@field enabled boolean
---@field hl_group string highlight group used to highlight global vars, default to 'ErrorMsg'

---@type Opts
local default_opts = {
  enabled = false,
  hl_group = 'ErrorMsg',
}

---Merge the default opts to user opts
---@param user_opts any
---@return Opts
local function merge(user_opts)
  local opts = vim.tbl_deep_extend('force', default_opts, user_opts)
  return opts
end

return { merge = merge }
