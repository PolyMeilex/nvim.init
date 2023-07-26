local lsp = require("lsp-zero").preset("recommended")

lsp.ensure_installed({
	'rust_analyzer',
})

lsp.on_attach(function(client, bufnr)
	lsp.default_keymaps({ buffer = bufnr })
end)

lsp.format_on_save({
	format_opts = {
		async = false,
		timeout_ms = 10000,
	},
	servers = {
		['lua_ls'] = { 'lua' },
		['rust_analyzer'] = { 'rust' },
	}
})

lsp.set_server_config({
	capabilities = {
		textDocument = {
			foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true
			}
		}
	}
})

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

lsp.setup()
