local M = {}

---@class TokenPos
---@field line integer 0-indexed
---@field col integer 0-indexed
---@field length integer

-- Find all ocurrence of pattern inside str
---@param str string
---@param pattern string
---@param plain boolean?
---@return table<integer> start_indices
function M.gfind(str, pattern, plain)
  local pat_start, pat_end
  local start = 1
  local indices = {}
  repeat
    pat_start, pat_end = string.find(str, pattern, start, plain)
    if pat_start then
      indices[#indices + 1] = pat_start
      start = pat_end + 1
    end
  until pat_start == nil
  return indices
end

---@param c string
---@return boolean
function M.is_digit(c)
  local code = string.byte(c)
  return code >= string.byte('0') and code <= string.byte('9')
end

---@param c string
---@return boolean
function M.is_letter(c)
  local code = string.byte(c)
  return (code >= string.byte('a') and code <= string.byte('z'))
    or (code >= string.byte('A') and code <= string.byte('Z'))
end

---@param c string
---@return boolean
function M.is_alpha_numeric(c)
  return M.is_letter(c) or M.is_digit(c)
end

return M
