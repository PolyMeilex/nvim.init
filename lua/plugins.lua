function IsNotVsCode()
	return vim.g.vscode == nil
end

return require('packer').startup(function(use)
	use 'wbthomason/packer.nvim'
	use 'bkad/CamelCaseMotion'
	use 'tpope/vim-surround'
	use {
		'svermeulen/vim-cutlass',
		config = function()
			require("config.cutlass")
		end,
	}

	use {
		'numToStr/Comment.nvim',
		cond = IsNotVsCode,
		config = function()
			require('Comment').setup()
		end
	}

	use {
		'f-person/git-blame.nvim',
		cond = IsNotVsCode,
		config = function()
			vim.cmd "GitBlameDisable"
		end
	}

	use {
		'lewis6991/gitsigns.nvim',
		cond = IsNotVsCode,
		config = function()
			require('gitsigns').setup()
		end,
	}

	use {
		'nvim-lualine/lualine.nvim',
		cond = IsNotVsCode,
		requires = {
			'nvim-tree/nvim-web-devicons',
			'SmiteshP/nvim-navic',
			'linrongbin16/lsp-progress.nvim',
		},
		config = function()
			require('config.lualine')
		end,
	}

	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.2',
		requires = {
			'nvim-lua/plenary.nvim',
			'nvim-telescope/telescope-file-browser.nvim',
			'nvim-telescope/telescope-ui-select.nvim',
		},
		cond = IsNotVsCode,
		config = function()
			require("config.telescope")
		end,
	}


	use {
		'nvim-tree/nvim-tree.lua',
		requires = 'nvim-tree/nvim-web-devicons',
		cond = IsNotVsCode,
		config = function()
			require("config.tree")
		end,
	}

	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		cond = IsNotVsCode,
		config = function()
			require("config.treesitter")
		end,
	}

	use {
		'kevinhwang91/nvim-ufo',
		requires = 'kevinhwang91/promise-async',
		cond = IsNotVsCode,
		config = function()
			require("config.ufo")
		end,
	}

	use {
		'VonHeikemen/lsp-zero.nvim',
		cond = IsNotVsCode,
		branch = 'v2.x',
		requires = {
			{ 'neovim/nvim-lspconfig' },
			{
				'williamboman/mason.nvim',
				run = function()
					pcall(vim.api.nvim_command, 'MasonUpdate')
				end,
			},
			{ 'williamboman/mason-lspconfig.nvim' },

			{ 'hrsh7th/nvim-cmp' },
			{ 'hrsh7th/cmp-nvim-lsp' },
			{ 'L3MON4D3/LuaSnip' },
			{ 'SmiteshP/nvim-navic' },
		},
		config = function()
			require("config.lsp")
		end,
	}

	use {
		'morhetz/gruvbox',
		cond = IsNotVsCode,
		config = function()
			require("config.colorscheme")
		end,
	}
end)
