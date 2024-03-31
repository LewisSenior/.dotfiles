--PACKAGE MANAGER
return require('packer').startup(function()
  use 'wbthomason/packer.nvim' -- so packer can update itself

  use 'chrisbra/csv.vim'

--Launches Omnisharp
  use {'neovim/nvim-lspconfig',
  'williamboman/mason.nvim'}-- native LSP support
  use 'hrsh7th/nvim-cmp' -- autocompletion framework
  use 'hrsh7th/cmp-nvim-lsp' -- LSP autocompletion provider
  use 'williamboman/mason-lspconfig.nvim'
-- Fuzzy finder
use {
  'nvim-telescope/telescope.nvim',
  requires = { {'nvim-lua/plenary.nvim'} }
}
-- Folder/File Tree
  use 'preservim/nerdtree'

--Code debugging, Breakpoints etc
  use 'puremourning/vimspector'

--Themeing
  use 'morhetz/gruvbox'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use { 'KeitaNakamura/highlighter.nvim', run = ':UpdateRemotePlugins'}

--Autocompleting for paths etc
--  use {'Shougo/deoplete.nvim', run = ':UpdateRemotePlugins' }
--  use 'ervandew/supertab'

--Bracket Pairing
  use 'tmsvg/pear-tree'
  use 'drewtempelmeyer/palenight.vim'
--  use 'prabirshrestha/asyncomplete.vim'
--  use 'majutsushi/tagbar' -- Lays out the structure of classes etc - could be useful
  use 'easymotion/vim-easymotion' -- Navigate document quickly via words, paragraphs etc
  use 'tpope/vim-fugitive' -- Git wrapper
  use 'idanarye/vim-merginal' -- Interface wrapper for vim-fugitive
  use {
  "folke/trouble.nvim",
  config = function()
    require("trouble").setup {
		icons = false,
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
} -- Error viewer

  use 'ryanoasis/vim-devicons'-- icons
  -- autocomplete config
local cmp = require 'cmp'
cmp.setup {
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    })
  },
  sources = {
    { name = 'nvim_lsp' },
  }
}

-- omnisharp lsp config
--require'lspconfig'.omnisharp.setup {
--  capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities()),
--  on_attach = function(_, bufnr)
--    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
--  end,
--  cmd = { "/home/lsenior/.omnisharp/run", "--languageserver" , "--hostPID", tostring(pid) },
--}
--
require("mason").setup()
require("mason-lspconfig").setup()
require'lspconfig'.phpactor.setup{}
require'lspconfig'.pyright.setup{}

	use 'ThePrimeagen/vim-be-good'


end)
