return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    { "MeanderingProgrammer/render-markdown.nvim", ft = { "markdown", "codecompanion" } },
  },
  config  = function()
    require("codecompanion").setup({
  		extensions = {
    		mcphub = {
      			callback = "mcphub.extensions.codecompanion",
      			opts = {
        -- MCP Tools 
        			make_tools = true,              -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
        			show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
        			add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
        			show_result_in_chat = true,      -- Show tool results directly in chat buffer
        			format_tool = nil,               -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
        -- MCP Resources
        			make_vars = true,                -- Convert MCP resources to #variables for prompts
        -- MCP Prompts 
        			make_slash_commands = true,      -- Add MCP prompts as /slash commands
      			}
    		}
  		},
		strategies = {
			chat = {
				adapter = "copilot",
				system_prompt = [[
        			You are a helpful coding assistant integrated into Neovim.
        			You can automatically use available MCP tools (e.g., code search, file edit)
        			when appropriate, without waiting for explicit user commands like @mcp.
      			]],
				tools = {
					default_tools = { "mcp" },
				},
			},
			inline = {
				adapter = "copilot",
			}
		},

		prompt_library = {
    		["MCP Chat"] = {
      			strategy = "chat",
      			description = "Start a chat with all MCP tools available",
      			opts = { is_slash_cmd = false, auto_submit = false, short_name = "mcp" },
      			prompts = {
        			{ role = "user", content = [[@{mcp} ]] }, -- injects the universal MCP group
      			},
    		},
  		},
		
      adapters = {
	  	http =  {
        	anthropic = function()
				return require("codecompanion.adapters").extend("anthropic", {
          			env = {
            			api_key = "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", -- Replace with your actual API key
          			},
        		})
				end,
		}
	}
    })

	vim.keymap.set("n", "<leader>am", function()
  require("codecompanion").prompt("mcp")
end, { desc = "CodeCompanion: MCP chat" })

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
