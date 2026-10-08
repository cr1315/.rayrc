" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
" Make sure you use single quotes
call plug#begin('~/.vim/plugged')

"#####################################################################
" Appearance is important!
"#####################################################################
Plug 'francoiscabrol/ranger.vim'
" map <leader>f :Ranger<CR>
" use ranger to open directory, but flash wired error
" let g:NERDTreeHijackNetrw = 0
" let g:ranger_replace_netrw = 1

Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'ryanoasis/vim-devicons'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'


"#####################################################################
" for file manager
"#####################################################################
" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
map <C-n> :NERDTreeToggle<CR>


"#####################################################################
" git series
"#####################################################################
" :Gblame, :Gdiffsplit
" Plug 'tpope/vim-fugitive'
"
" show indicators on left side: + - ~
" Plug 'airblade/vim-gitgutter'


"#####################################################################
" fzf series
"#####################################################################
" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" auto change current dir to Project root
" Plug 'airblade/vim-rooter'


"#####################################################################
" sample for adding plugins
"#####################################################################
" Using a non-default branch
" Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Using a tagged release; wildcard allowed (requires git 1.9.2 or above)
" Plug 'fatih/vim-go', { 'tag': '*' }

" Plugin options
" Plug 'nsf/gocode', { 'tag': 'v.20150303', 'rtp': 'vim' }

" Unmanaged plugin (manually installed and updated)
" Plug '~/my-prototype-plugin'

" Initialize plugin system
call plug#end()

try
    colorscheme dracula
catch
endtry