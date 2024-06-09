vim.g.mapleader = " "

require("hjklsynner.myconfig")
require("hjklsynner.remap")
require("hjklsynner.opt")

vim.g.vimspector_enable_mappings = 'HUMAN'


vim.g.highlighter = {
    auto_update = 2,
    project_root_signs = { '.git' }
}
vim.opt.wrap = false
vim.opt.tabstop=4
vim.opt.shiftwidth=4
vim.opt.encoding="UTF-8"
vim.opt.hidden = true
vim.opt.ma = true
vim.cmd('filetype indent plugin on')
vim.cmd('syntax enable')


vim.g.gruvbox_contrast_dark='hard'
vim.g.gruvbox_contrast_dark='hard'
vim.g.NERDTreeShowHidden=1
vim.g.NERDTreeMapActivateNode='l'
vim.g.gruvbox_contrast_dark='hard'
vim.g.NERDTreeShowHidden=1
vim.g.NERDTreeMapActivateNode='l'

vim.g.WebDevIconsNerdTreeAfterGlyphPadding = '  '


vim.g.airline = {
	extensions = {
		tabline = {
			enabled = 1
		},
		hunks = {
			enabled = 1
		},
		branch = {
			enabled = 1
		},
	},
}

--vim.g.airline_section_b = '%{strftime("%c")}'
vim.g.airline_section_c = 'WN: %{winnr()}'
vim.g.airline_section_y = 'BN: %{bufnr("%")} %{&encoding}'
vim.g.airline_powerline_fonts = 1

vim.g.term_buf = 0
vim.gterm_win = 0

vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])



vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    -- This will disable virtual text, like doing:
    -- vim.g.diagnostic_enable_virtual_text = 0
    virtual_text = false,

    -- This is similar to:
    -- vim.g.diagnostic_show_sign = 1
    -- To configure sign display,
    --  see: ":help vim.lsp.diagnostic.set_signs()"
    signs = true,

    -- This is similar to:
    -- "vim.g.diagnostic_insert_delay = 1"
    update_in_insert = true,
  }
)

require('telescope').setup({
		pickers = {
			find_files = {
				hidden = true
			}
		},
		defaults = {
			winblend = 0,
		},
})

local builtin = require("telescope.builtin")
local actions = require('telescope.actions')
vim.opt_local.conceallevel = 2

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>xx', ':Trouble diagnostics toggle<cr>', { noremap = true, silent = true })

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

require("mason").setup()
require("mason-lspconfig").setup()

require'lspconfig'.phpactor.setup{}
require'lspconfig'.basedpyright.setup{
settings = { 
	basedpyright = {
		analysis = {
			typeCheckingMode = "standard"
		}
	}
}
}
require'lspconfig'.omnisharp.setup{}
