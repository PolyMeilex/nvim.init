local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

local M = {}

M.mark = function(config, node, state)
  local red = "GruvboxRed"
  local dim = highlights.DIM_TEXT
  local mark = node.extra.mark

  if mark == 1 then
    return {
      {
        text = "H",
        highlight = red,
      },
    }
  elseif mark == 2 then
    return {
      {
        text = " ",
        highlight = dim,
      },
      {
        text = "J",
        highlight = red,
      },
    }
  elseif mark == 3 then
    return {
      {
        text = "  ",
        highlight = dim,
      },
      {
        text = "K",
        highlight = red,
      },
    }
  elseif mark == 4 then
    return {
      {
        text = "   ",
        highlight = dim,
      },
      {
        text = "L",
        highlight = red,
      },
    }
  end
end

return vim.tbl_deep_extend("force", common, M)
