set nocompatible " disable vi compatibility
syntax on " turn syntax highlighting on 
set number relativenumber " turn hybrid line numbers on
set ruler " show line, col number in status bar

" more generic search
set ignorecase
set smartcase

" use indentation of previous line
set autoindent

" alternative tab settings with spaces instead of hard tabs 
set expandtab
set smarttab
set tabstop=4
set shiftwidth=4

" tab completion for files/bufferss
set wildmode=longest,list
set wildmenu

" open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" automatic brace completion
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O

" F2 will save the file
nmap <F2> :w<CR>
" in insert mode F2 will exit insert, save, enter insert again
imap <F2> <ESC>:w<CR>a
" Press F3 to toggle highlighting on/off, and show current value.
:noremap <F3> :set hlsearch! hlsearch?<CR>
" toggle spellcheck
map <F4> :setlocal spell! spelllang=en_us<CR>

" save undo history across sessions
set undofile
set undodir=~/.vim/undo/

" reuse buffers of files which are already open, useful for quickfix
set switchbuf=useopen

" show visual line under cursors's current line
set cursorline

" enable full python syntax highlighting
let python_highlight_all = 1

" for python files
nnoremap <leader>d oimport pdb; pdb.set_trace()<Esc>

" plugins
filetype plugin on
call plug#begin()
Plug 'morhetz/gruvbox'
Plug 'ycm-core/YouCompleteMe'
Plug 'google/yapf'
Plug 'preservim/nerdcommenter'
call plug#end()

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" color scheme
colorscheme gruvbox
set background=dark

" YCM close preview window automatically
let g:ycm_autoclose_preview_window_after_completion = 1

