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
cmp.setup ({
  mapping = {
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    })
  },
  completion = {
	  autocomplete = { require('cmp.types').cmp.TriggerEvent.TextChanged },
  },
  experimental = {
      ghost_text = true, -- Shows suggestions inline as you type
  },
  sources = {
    { name = 'nvim_lsp' },
	{ name = 'buffer' },
	{ name = 'path' }
  },
  formatting = {
	  format = function(entry, item)
		  item.menu = ({
			  nvim_lsp = '[LSP]',
			  buffer = '[Buffer]',
			  path = '[Path]',
		  })[entry.source.name]
		  return item
	  end,
  },
  preselect = cmp.PreselectMode.Item,
})


require("mason").setup()
require("mason-lspconfig").setup()

local capabilities = require('cmp_nvim_lsp').default_capabilities()
vim.lsp.config['intelephense'] = {
  capabilities = capabilities,
  on_attach = on_attach,
  autostart = true,
}

vim.lsp.config['basedpyright'] = {
  capabilities = capabilities,
  on_attach = on_attach,
  autostart = true,
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
      },
    },
  },
}

vim.lsp.config['bashls'] = {
  capabilities = capabilities,
  on_attach = on_attach,
  autostart = true,
  flags = { debounce_text_changes = 150 },
  settings = {
    bashIde = {
      globPattern = "**/*.?(e)x?(a)m?(p)l?(e)",
      lintOnSave = true,
      autoAddShebang = true,
    },
  },
}


local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)

vim.keymap.set("n", "<C-j>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-k>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-l>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-m>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<leader>j", function() harpoon:list():prev() end)
vim.keymap.set("n", "<leader>k", function() harpoon:list():next() end)

local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
            results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end

vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
    { desc = "Open harpoon window" })
