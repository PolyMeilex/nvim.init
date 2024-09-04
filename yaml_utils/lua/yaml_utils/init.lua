local namespace_id = vim.api.nvim_create_namespace("yaml_utils")

local function get_keys(root)
  local keys = {}
  for node, name in root:iter_children() do
    if name == "key" then
      table.insert(keys, node)
    end

    if node:child_count() > 0 then
      for _, child in pairs(get_keys(node)) do
        table.insert(keys, child)
      end
    end
  end
  return keys
end

-- Public API

local M = {}

M.is_yaml = function() return vim.bo.filetype == "yaml" end

M.all_keys = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  local tree = vim.treesitter.get_parser(bufnr, ft):parse()[1]
  local root = tree:root()
  return get_keys(root)
end

M.setup = function() end

M.clear = function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
end

M.seq_ids = function(key_filter, count_nested_flow_seq)
  if not M.is_yaml() then return end

  M.clear()

  local bufnr = vim.api.nvim_get_current_buf()

  -- TODO: Optimise M.all_keys(), or simply remove it all together
  for _, node in pairs(M.all_keys()) do
    if key_filter ~= nil then
      local key_as_string = vim.treesitter.get_node_text(node, bufnr)
      if key_as_string ~= key_filter then
        goto continue
      end
    end

    local parent = node:parent()

    if parent == nil then
      goto continue
    end

    local value = parent:field("value")[1]

    if value == nil then
      goto continue
    end

    if value:type() ~= "block_node" then
      goto continue
    end

    local child = value:child()

    if child == nil then
      goto continue
    end

    if child:type() ~= "block_sequence" then
      goto continue
    end

    local id = 0
    for block_sequence, _ in child:iter_children() do
      if block_sequence:type() ~= "block_sequence_item" then
        goto continue
      end

      local current_id = id

      -- Count nested flow seq as root elements
      if count_nested_flow_seq then
        local block_child = block_sequence:named_child(0)
        if block_child ~= nil and block_child:type() == "flow_node" then
          block_child = block_child:child()

          if block_child ~= nil and block_child:type() == "flow_sequence" then
            local count = block_child:named_child_count()
            if count > 1 then
              id = id + count - 1
            end
          end
        end
      end

      local line, col = block_sequence:start()
      local key = tostring(current_id)
      local virt_text = {
        { key, "Comment" },
        { " ", "Comment" },
      }

      vim.api.nvim_buf_set_extmark(
        bufnr,
        namespace_id,
        line,
        col,
        {
          virt_text_pos = "inline",
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
vim.api.nvim_create_user_command("YAMLSeqIds", function()
  M.seq_ids(nil, true)
end, { desc = "Mark seq ids" })

vim.api.nvim_create_augroup("yaml_utils", { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
  group = "yaml_utils",
  callback = function()
    M.seq_ids("messages", true)
  end,
})

return M
