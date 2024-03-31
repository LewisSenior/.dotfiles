lua require('plugins')
let g:vimspector_enable_mappings = 'HUMAN'
let g:highlighter#auto_update = 2
let g:highlighter#project_root_signs = ['.git']
let mapleader = " " 
set nowrap
set tabstop=4
set shiftwidth=4
set encoding=UTF-8
set hidden
filetype indent plugin on
syntax enable

luafile ~/.config/nvim/myconfig.lua

lua << EOF
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    -- This will disable virtual text, like doing:
    -- let g:diagnostic_enable_virtual_text = 0
    virtual_text = false,

    -- This is similar to:
    -- let g:diagnostic_show_sign = 1
    -- To configure sign display,
    --  see: ":help vim.lsp.diagnostic.set_signs()"
    signs = true,

    -- This is similar to:
    -- "let g:diagnostic_insert_delay = 1"
    update_in_insert = true,
  }
)
EOF

" Git fugative keys
nnoremap <leader>gs <cmd>G<cr>
nnoremap <leader>ga <cmd>w!<cr><cmd>Git add %<cr>
nnoremap <leader>gc <cmd>Git commit<cr>
nnoremap <leader>gp <cmd>Git push<cr>
nnoremap <leader>q  <cmd>q<cr>

nnoremap <C-f> <cmd>silent !tmux neww tmux-sessionizer<CR>

if !exists('g:highlighter#syntax_cs')
  let g:highlighter#syntax_cs = [
        \ { 'hlgroup'       : 'HighlighterCsClass',
        \   'hlgroup_link'  : 'Identifier',
        \   'tagkinds'      : 'c',
        \ },
        \ { 'hlgroup'       : 'HighlighterCsMethod',
        \   'hlgroup_link'  : 'Function',
        \   'tagkinds'      : 'ms',
        \ }]
endif

set termguicolors
set fileencodings=utf-8,latin1
set encoding=utf-8
set listchars=tab:>·,trail:•
set list
set ff=unix
set background=dark
let g:gruvbox_contrast_dark='hard'
colorscheme gruvbox

set relativenumber
set number
let g:WebDevIconsNerdTreeAfterGlyphPadding = '  '


" airline config
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#hunks#enabled=1
let g:airline#extensions#branch#enabled=1

"let g:airline_section_b = '%{strftime("%c")}'
let g:airline_section_c = 'WN: %{winnr()}'
let g:airline_section_y = 'BN: %{bufnr("%")} %{&encoding}'
let g:airline_powerline_fonts = 1

nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle lsp_workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle lsp_document_diagnostics<cr><c-w>k
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
nnoremap gR <cmd>TroubleToggle lsp_references<cr>
let g:term_buf = 0
let g:term_win = 0

" Toggle terminal on/off (neovim)
nnoremap <A-t> :call TermToggle(12)<CR>
inoremap <A-t> <Esc>:call TermToggle(12)<CR>
tnoremap <A-t> <C-\><C-n>:call TermToggle(12)<CR>

" Terminal go back to normal mode
tnoremap <Esc> <C-\><C-n>
tnoremap :q! <C-\><C-n>:q!<CR>


let NERDTreeShowHidden=1
let NERDTreeMapActivateNode='l'
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap('<leader>fu', 'Telescope lsp_references')
nnoremap('<leader>gd', 'Telescope lsp_definitions')
nnoremap('<leader>rn', 'lua vim.lsp.buf.rename()')
nnoremap('<leader>dn', 'lua vim.lsp.diagnostic.goto_next()')
nnoremap('<leader>dN', 'lua vim.lsp.diagnostic.goto_prev()')
nnoremap('<leader>dd', 'Telescope lsp_document_diagnostics')
nnoremap('<leader>dD', 'Telescope lsp_workspace_diagnostics')
nnoremap('<leader>xx', 'Telescope lsp_code_actions')
noremap('<leader>xd', '%Telescope lsp_range_code_actions')
if exists("g:loaded_webdevicons")
  call webdevicons#refresh()
endif
