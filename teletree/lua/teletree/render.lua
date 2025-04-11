local NuiLine = require("nui.line")

local M = {}

function M.prepare_node(node, _)
  if not node.text then
    error("missing node.text")
  end

  local texts = node.text

  if type(node.text) ~= "table" or node.text.content then
    texts = { node.text }
  end

  local lines = {}

  for i, text in ipairs(texts) do
    local line = NuiLine()

    line:append(string.rep("  ", node._depth - 1))

    if node.is_directory then
      line:append(" ")
      if node:is_expanded() then
        line:append(" ", "GruvboxGreenBold")
      else
        line:append(" ", "GruvboxGreenBold")
      end
      line:append(text, "GruvboxGreenBold")
    else
      if node.icon then
        line:append(" ")
        line:append(node.icon, node.icon_highlight or "Normal")
        line:append(" ")
      else
        line:append(" ")
        line:append("")
        line:append(" ")
      end

      line:append(text)
    end

    table.insert(lines, line)
  end

  return lines
end

return M
