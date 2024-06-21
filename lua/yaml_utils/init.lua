local document = require("yaml_utils.document")
local namespace_id = vim.api.nvim_create_namespace("yaml_utils")

local function is_yaml() return vim.bo.filetype == "yaml" end

-- Public API

local M = {}

M.setup = function() end

M.clear = function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
end

M.seq_ids = function()
  if not is_yaml() then return end

  M.clear()

  local bufnr = vim.api.nvim_get_current_buf()

  for _, node in pairs(document.all_keys()) do
    -- local key_as_string = vim.treesitter.get_node_text(node, bufnr)

    local parent = node:parent()
    local value = parent:field("value")[1]

    if value:type() ~= "block_node" then
      goto continue
    end

    local child = value:child()
    if child:type() ~= "block_sequence" then
      goto continue
    end

    local id = 0
    for block_sequence, _ in child:iter_children() do
      if block_sequence:type() ~= "block_sequence_item" then
        goto continue
      end


      local line, col = block_sequence:start()
      local virt_text = {}
      local key = tostring(id)
      table.insert(virt_text, { key, "Comment" })

      vim.api.nvim_buf_set_extmark(
        bufnr,
        namespace_id,
        line,
        col - 2,
        {
          virt_text_pos = "overlay",
          -- TODO: once nvim 10 is done
          -- virt_text_pos = "inline",
          virt_text = virt_text,
        }
      )

      id = id + 1

      ::continue::
    end

    ::continue::
  end
end

-- Commands

vim.api.nvim_create_user_command("YAMLClear", M.clear, { desc = "Clear marks" })
vim.api.nvim_create_user_command("YAMLSeqIds", M.seq_ids, { desc = "Mark seq ids" })

return M
