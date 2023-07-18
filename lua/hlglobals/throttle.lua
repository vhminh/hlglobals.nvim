---https://github.com/nvim-treesitter/nvim-treesitter-context/blob/6f8f788738b968f24a108ee599c5be0031f94f06/lua/treesitter-context.lua#L388
---@generic F: function
---@param f F
---@param ms? number
---@return F
return function(f, ms)
  ms = ms or 200
  local timer = assert(vim.loop.new_timer())
  local waiting = 0
  return function()
    if timer:is_active() then
      waiting = waiting + 1
      return
    end
    waiting = 0
    f() -- first call, execute immediately
    timer:start(ms, 0, function()
      if waiting > 1 then
        vim.schedule(f) -- only execute if there are calls waiting
      end
    end)
  end
end
