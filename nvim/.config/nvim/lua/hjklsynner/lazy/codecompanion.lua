return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    { "MeanderingProgrammer/render-markdown.nvim", ft = { "markdown", "codecompanion" } },
  },
  config  = function()
    require("codecompanion").setup({
		strategies = {
			chat = {
				adapter = "anthropic",
			},
			inline = {
				adapter = "anthropic",
			}
		},
      adapters = {
        anthropic = function()
			return require("codecompanion.adapters").extend("anthropic", {
          		env = {
            		api_key = "", -- Replace with your actual API key
          		},
        	})
		end,
	}
    })

	local treesitter_opt = {
		ensure_installed = { "php", "html", "blade", "php_only" },
		highlight = {
			enable = true,
		},
	}

	require("nvim-treesitter.configs").setup(treesitter_opt)

	local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
	parser_config.blade = {
		install_info = {
        	url = "https://github.com/EmranMR/tree-sitter-blade",
        	files = { "src/parser.c" },
        	branch = "main",
    	},
    	filetype = "blade",
	}

	vim.filetype.add({
		pattern = {
			[".*%.blade%.php"] = "blade",
		},
	})
	end,
}
