vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local function on_attach(bufnr)
	local api = require('nvim-tree.api')

	api.config.mappings.default_on_attach(bufnr)

	vim.keymap.set('n', '<C-e>', api.tree.close, { buffer = bufnr })

	vim.keymap.set('n', '<S-f>', function()
		local node = api.tree.get_node_under_cursor()
		if node.nodes == nil then return end

		local builtin = require('telescope.builtin')
		builtin.live_grep({ cwd = node.absolute_path })
	end, { buffer = bufnr })
end

local api = require("nvim-tree.api")
vim.keymap.set('n', '<C-e>', api.tree.focus, {})

require("nvim-tree").setup({
	on_attach = on_attach,
	tab = {
		sync = {
			open = true,
			close = true,
		}
	}
})
