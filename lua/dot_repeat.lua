---@type fun(motion: fun(motion: string): string)
local set_operatorfunc = vim.fn[vim.api.nvim_exec(
  [[
  func s:set_opfunc(val)
    let &operatorfunc = a:val
  endfunc
  echon get(function('s:set_opfunc'), 'name')
]],
  true
)]

---@param fn fun(...): any
---@vararg any
local dot_repeat = function(fn, ...)
  local args = ...
  ---@type fun(motion: string): string
  local op
  op = function(motion)
    if motion == nil then
      set_operatorfunc(op)
      return "g@l"
    end
    fn(args)
    return ""
  end

  return op
end

return dot_repeat
