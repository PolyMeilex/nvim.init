local lsp = require('lsp-zero').preset('recommended')

lsp.ensure_installed({
	'rust_analyzer',
})

lsp.on_attach(function(client, bufnr)
	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint(bufnr, true)
	end

	if client.server_capabilities.documentSymbolProvider then
		require('nvim-navic').attach(client, bufnr)
	end

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
			},
			inlayHints = true,
		}
	}
})

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())
-- vim.o.statusline = "%f %= %{%v:lua.require'nvim-navic'.get_location()%}"

lsp.setup()
