---@class RenuiText
---@field protected extmark? vim.api.keyset.set_extmark
local Text = {}
Text.__index = Text

---@param content string text content or NuiText object
---@param extmark? string|vim.api.keyset.set_extmark highlight group name or extmark options
function Text:new(content, extmark)
  local this = setmetatable({}, self)
  this:set(content, extmark)
  return this
end

---@param content string text content
---@param extmark? string|vim.api.keyset.set_extmark highlight group name or extmark options
---@return RenuiText
function Text:set(content, extmark)
  if self._content ~= content then
    self._content = content
    self._length = vim.fn.strlen(content)
    self._width = vim.api.nvim_strwidth(content)
  end

  if extmark then
    -- preserve self.extmark.id
    local id = self.extmark and self.extmark.id or nil

    if type(extmark) == "string" then
      self.extmark = { hl_group = extmark }
    else
      self.extmark = vim.deepcopy(extmark)
    end

    self.extmark.id = id
  end

  return self
end

---@return string
function Text:content()
  return self._content
end

---@return number
function Text:length()
  return self._length
end

---@return number
function Text:width()
  return self._width
end

---@param bufnr number buffer number
---@param ns_id number namespace id
---@param linenr number line number (1-indexed)
---@param byte_start number start byte position (0-indexed)
---@return nil
function Text:highlight(bufnr, ns_id, linenr, byte_start)
  if not self.extmark then
    return
  end

  self.extmark.end_col = byte_start + self:length()
  self.extmark.id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr - 1, byte_start, self.extmark)
end

return Text
