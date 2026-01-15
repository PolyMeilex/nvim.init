local NuiLine = require("nui.line")

local M = {}

---@param node TeletreeNode
function M.prepare_node(node, _)
  if not node.text then
    error("missing node.text")
  end

  local texts = node.text

  if type(node.text) ~= "table" or node.text.content then
    texts = { node.text }
  end

  local lines = {}

  for _, text in pairs(texts) do
    local line = NuiLine()

    line:append(string.rep("  ", node._depth - 1))

    local hi = nil
    local icon = nil
    if node.diagnostics == vim.diagnostic.severity.ERROR then
      hi = "DiagnosticError"
      icon = ""
    elseif node.diagnostics == vim.diagnostic.severity.WARN then
      hi = "DiagnosticWarn"
      icon = ""
    end

    if node.is_directory then
      line:append(" ")
      if text ~= "./" then
        if node:is_expanded() then
          line:append(" ", "GruvboxGreenBold")
        else
          line:append(" ", "GruvboxGreenBold")
        end
      end
      line:append(text, hi or "GruvboxGreenBold")
    else
      local web_devicons = require("nvim-web-devicons")
      local file_icon, highlight = web_devicons.get_icon(node.text)

      if file_icon then
        line:append(" ")
        line:append(file_icon, highlight or "Normal")
        line:append(" ")
      else
        line:append(" ")
        line:append("")
        line:append(" ")
      end

      line:append(text, hi)
    end

    if icon then
      line:append(" ")
      line:append(icon, hi)
    end

    table.insert(lines, line)
  end

  return lines
end

return M
