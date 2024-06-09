return	{
	"folke/trouble.nvim",
	opts = {},
	cmd = "Trouble",
	keys = {
		{
		"<leader>xx",
		"<cmd>Trouble diagnostics toggle<cr>",
		desc = "Diagnotics (Trouble)",
		},
		{
		"<leader>cl",
		"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
		desc = "LSP Definitions / references / ... (Trouble)",
		},
	}
}
