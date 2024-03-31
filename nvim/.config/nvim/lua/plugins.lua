require("lazy").setup({
	'wbthomason/packer.nvim',
	'chrisbra/csv.vim',
	{'neovim/nvim-lspconfig',
		dependencies = {
			'williamboman/mason.nvim' }
	},
	'hrsh7th/nvim-cmp',
	'hrsh7th/cmp-nvim-lsp',
	'williamboman/mason-lspconfig.nvim',
	{'nvim-telescope/telescope.nvim',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},

	'preservim/nerdtree',

--Code debugging, Breakpoints etc
	'puremourning/vimspector',

--Themeing
	'morhetz/gruvbox',
	'vim-airline/vim-airline',
	'vim-airline/vim-airline-themes',
	{ 'KeitaNakamura/highlighter.nvim', run = ':UpdateRemotePlugins'},



	'drewtempelmeyer/palenight.vim',
--  use 'prabirshrestha/asyncomplete.vim'
--  use 'majutsushi/tagbar' -- Lays out the structure of classes etc - could be useful
	'easymotion/vim-easymotion', -- Navigate document quickly via words, paragraphs etc
	'tpope/vim-fugitive', -- Git wrapper
	'idanarye/vim-merginal', -- Interface wrapper for vim-fugitive
	{ "folke/trouble.nvim", config = function()
    require("trouble").setup {
		icons = false,
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
}, -- Error viewer

'ryanoasis/vim-devicons',-- icons

'ThePrimeagen/vim-be-good'
})
