local namespace_id = vim.api.nvim_create_namespace("yaml_utils")

local function keys_quary()
  return vim.treesitter.query.parse(
    "yaml",
    [[
      ;; query
      ((block_mapping_pair
         value: (block_node
          (block_sequence (block_sequence_item)) @root
         )
      ))
    ]]
  )
end

local function filtered_keys_quary(key_filter)
  local query_string = [[
    ;; query
    ((block_mapping_pair
       key: (flow_node (plain_scalar (string_scalar) @_key (#eq? @_key %s)))
       value: (block_node
        (block_sequence (block_sequence_item)) @root
       )
    ))
  ]]

  query_string = string.format(query_string, key_filter)

  return vim.treesitter.query.parse("yaml", query_string)
end

local function cached_keys_quary()
  local cache = nil
  return function()
    if cache == nil then
      local ok, quary = pcall(keys_quary)
      if ok then
        cache = quary
      end
    end

    return cache
  end
end

local function cached_filtered_seq_query()
  local cache = nil
  return function()
    if cache == nil then
      local ok, quary = pcall(filtered_keys_quary, "messages")
      if ok then
        cache = quary
      end
    end

    return cache
  end
end

local seq_query = cached_keys_quary()
local filtered_seq_query = cached_filtered_seq_query()

-- Public API

local M = {}

M.is_yaml = function()
  return vim.bo.filetype == "yaml"
end

M.all_keys = function(bufnr, key_filter)
  local tree = vim.treesitter.get_parser(bufnr, "yaml"):parse()[1]
  local root = tree:root()

  local q = nil
  if key_filter == nil then
    q = seq_query()
  else
    q = filtered_seq_query()
  end

  if q == nil then
    return
  end

  local iter = q:iter_captures(root, bufnr)
  return function()
    for id, node in iter do
      if q.captures[id] == "root" then
        return node
      end
    end

    return nil
  end
end

M.setup = function() end

M.clear = function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
end

M.seq_ids = function(key_filter, count_nested_flow_seq)
  if not M.is_yaml() then
    return
  end

  M.clear()

  local bufnr = vim.api.nvim_get_current_buf()

  for node in M.all_keys(bufnr, key_filter) do
    local id = 0
    for block_sequence, _ in node:iter_children() do
      local current_id = id

      if block_sequence:type() ~= "block_sequence_item" then
        goto continue
      end

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

      vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line, col, {
        virt_text_pos = "inline",
        virt_text = virt_text,
      })

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
vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
  group = "yaml_utils",
  pattern = "*.yaml,*.yml",
  callback = function()
    M.seq_ids("messages", true)
  end,
})

return M
