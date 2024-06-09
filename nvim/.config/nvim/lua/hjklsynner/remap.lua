vim.keymap.set("n", "<leader>gs", "<cmd>G<cr>")
vim.keymap.set("n", "<leader>ga", "<cmd>w!<cr><cmd>Git add %<cr>")
vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>")
vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>")
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<cr>")
vim.keymap.set("n", "<leader>n", "<cmd>NERDTreeFocus<cr>")
vim.keymap.set("n", "<leader>t", "<cmd>NERDTreeToggle<cr>")
vim.keymap.set("n", "<leader>fu", "<cmd>Telescope lsp_references<cr>")
vim.keymap.set("n", "<leader>gd", "<cmd>Telescope lsp_definitions<cr>")
vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>")
vim.keymap.set("n", "<leader>dn", "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>")
vim.keymap.set("n", "<leader>dN", "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>")
vim.keymap.set("n", "<leader>dd", "<cmd>Telescope lsp_document_diagnostics<cr>")
vim.keymap.set("n", "<leader>dD", "<cmd>Telescope lsp_workspace_diagnostics<cr>")
vim.keymap.set("n", "<leader>xx", "<cmd>Telescope lsp_code_actions<cr>")
vim.keymap.set("n", "<leader>xd", "<cmd>%Telescope lsp_range_code_actions<cr>")