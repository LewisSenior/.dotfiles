return {
	{
    "ravitemer/mcphub.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest",  -- Installs `mcp-hub` node binary globally
    config = function()
        require("mcphub").setup({
            auto_approve = function(params)
                if params.server_name == "neovim" then
                    local read_tools = {
                        read_file = true,
                        read_multiple_files = true,
                        list_directory = true,
                        find_files = true,
                    }
                    if read_tools[params.tool_name] then
                        return true -- Auto-approve all read-based operations
                    end
                    -- Auto-approve resource access for all listed resources
                    local approved_resources = {
                        ["neovim://buffer"] = true,
                        ["neovim://workspace"] = true,
                        ["neovim://diagnostics/buffer"] = true,
                        ["neovim://diagnostics/workspace"] = true,
                    }
                    local uri = params.resource_uri or params.uri
                    if uri and approved_resources[uri] then
                        return true -- Auto-approve resource access
                    end
                end
                return false -- Show confirmation for others
            end,
        })
    end
}
}
