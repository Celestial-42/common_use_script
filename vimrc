"set encoding=utf-8
"set fileencodings=utf-8,chinese,latin-1
"if has("win32")
"    set fileencoding=chinese
"else
"    set fileencoding=utf-8
"endif
"source $VIMRUNTIME/delmenu.vim
"source $VIMRUNTIME/menu.vim
"language messages zh_CN.utf-8
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,cp936,gb2312,big5,euc-jp,euc-kr,latin1
let &termencoding=&encoding
language messages zh_CN.utf-8

iab esle else
iab beign begin
iab edn end
iab awlays always
iab alws always @(posedge clk or negedge rst_n) begin<CR>if(~rst_n)<CR>end<ESC>00dwko<ESC>i
iab alwc always @(*) begin<CR>end<ESC>k00o
iab _segment // ---------------------------------------------------<CR><CR>---------------------------------------------------
iab _line // **********<ESC>5hi
set cuc
set cul
set textwidth=0
set lines=30 columns=100
nmap sc :source $HOME/.vimrc<CR>
nmap ec :tabnew $HOME/.vimrc<CR>
nmap ct :tabc<CR>
nmap cot :tabo<CR>
nmap at :tabs<CR>
set nowrap
set hls
set nocompatible
set number
set ruler
set showcmd
set history=1000
set nobackup
set cindent
syntax enable
syntax on
set noic
set smartcase
set incsearch
set backspace=indent,eol,start
set mouse=a
set tabstop=4
set shiftwidth=4
set smarttab
set softtabstop=4
set expandtab
set showtabline=1
filetype on
filetype indent on
filetype plugin indent on
map <C-S> :update<cr>
map <C-A> ggVG
map <C-Z> /asdfghjkl<CR>
map <A-`> <ESC>
" colorscheme molokai
set background=dark
colorscheme wombat256grf
set guifont=Space\ Mono\ 10
nmap wm :NERDTreeToggle<cr>
" NERDTree settings
let NERDTreeWinSize = 15
let NERDTreeMouseMode = 2
let NERDTreeCustomOpenArgs={'file':{'where': 't'}}
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTreeType == "primary") | q |endif

" Set options and add mapping such that Vim behaves a lot like MS-Windows
"
" Maintainer: Bram Moolenaar <Bram@vim.org>
" Last Change:  2018 Dec 07

" Bail out if this isn't wanted.
if exists("g:skip_loading_mswin") && g:skip_loading_mswin
  finish
endif

" set the 'cpoptions' to its Vim default
if 1  " only do this when compiled with expression evaluation
  let s:save_cpo = &cpoptions
endif
set cpo&vim

" backspace and cursor keys wrap to previous/next line
set backspace=indent,eol,start whichwrap+=<,>,[,]

" backspace in Visual mode deletes selection
vnoremap <BS> d

if has("clipboard")
    " CTRL-X and SHIFT-Del are Cut
    vnoremap <C-X> "+x
    vnoremap <S-Del> "+x

    " CTRL-C and CTRL-Insert are Copy
    vnoremap <C-C> "+y
    vnoremap <C-Insert> "+y

    " CTRL-V and SHIFT-Insert are Paste
    map <C-V>   "+gP
    map <S-Insert>    "+gP

    cmap <C-V>    <C-R>+
    cmap <S-Insert>   <C-R>+
endif

" Pasting blockwise and linewise selections is not possible in Insert and
" Visual mode without the +virtualedit feature.  They are pasted as if they
" were characterwise instead.
" Uses the paste.vim autoload script.
" Use CTRL-G u to have CTRL-Z only undo the paste.

if 1
    exe 'inoremap <script> <C-V> <C-G>u' . paste#paste_cmd['i']
    exe 'vnoremap <script> <C-V> ' . paste#paste_cmd['v']
endif

imap <S-Insert>   <C-V>
vmap <S-Insert>   <C-V>

" Use CTRL-Q to do what CTRL-V used to do
noremap <C-Q>   <C-V>

" For CTRL-V to work autoselect must be off.
" On Unix we have two selections, autoselect can be used.
if !has("unix")
  set guioptions-=a
endif

" CTRL-A is Select all
noremap <C-A> gggH<C-O>G
noremap <A-Q> *
inoremap <C-A> <C-O>gg<C-O>gH<C-O>G
cnoremap <C-A> <C-C>gggH<C-O>G
onoremap <C-A> <C-C>gggH<C-O>G
snoremap <C-A> <C-C>gggH<C-O>G
xnoremap <C-A> <C-C>ggVG
xnoremap <C-G> G
map Q <Nop>
map C <C-C>
map S <C-S>
map C ci(

if has("gui")
  " CTRL-F is the search dialog
  noremap  <expr> <C-F> has("gui_running") ? ":promptfind\<CR>" : "/"
  inoremap <expr> <C-F> has("gui_running") ? "\<C-\>\<C-O>:promptfind\<CR>" : "\<C-\>\<C-O>/"
  cnoremap <expr> <C-F> has("gui_running") ? "\<C-\>\<C-C>:promptfind\<CR>" : "\<C-\>\<C-O>/"

  " CTRL-H is the replace dialog,
  " but in console, it might be backspace, so don't map it there
  nnoremap <expr> <C-H> has("gui_running") ? ":promptrepl\<CR>" : "\<C-H>"
  inoremap <expr> <C-H> has("gui_running") ? "\<C-\>\<C-O>:promptrepl\<CR>" : "\<C-H>"
  cnoremap <expr> <C-H> has("gui_running") ? "\<C-\>\<C-C>:promptrepl\<CR>" : "\<C-H>"
endif

" restore 'cpoptions'
set cpo&
if 1
  let &cpoptions = s:save_cpo
  unlet s:save_cpo
endif

" winpos 137 70

map <F7> :call FileHead()<CR><C-I>
"autocmd BufWrite *.v call SetLastModifiedTimes()
au BufNewFile,BufRead *.sv  set filetype=verilog_systemverilog
au BufNewFile,BufRead *.svh set filetype=verilog_systemverilog
au BufNewFile,BufRead *.svn-base set filetype=verilog_systemverilog

if exists('g:my_function')
    finish
endif


function FileHead()
"    call append(0 ,"`timescale 1ns / 1ps")
    call append(0 ,"//////////////////////////////////////////////////////////////////////////////////")
    call append(1 ,"// Company       : ")
    call append(2 ,"// Engineer      : ()")
    call append(3 ,"// ")
    call append(4 ,"// Create Date   : ".strftime("%Y-%m-%d"))
    call append(5 ,"// Design Name   : ")
    call append(6 ,"// Module Name   : ".expand("%:r"))
    call append(7 ,"// Project Name  : ")
    call append(8 ,"// Target Devices: ")
    call append(9 ,"// Tool Versions : ")
    call append(10,"// Description   : ")
    call append(11,"// ")
    call append(12,"// Dependencies  : ")
    call append(13,"// ")
    call append(14,"// Revision      :")
    call append(15,"// Revision 0.01 - File Created")
    call append(16,"// Additional Comments:")
    call append(17,"// ")
    call append(18,"//////////////////////////////////////////////////////////////////////////////////")
   " call append(20,"module ".toupper(expand("%:r"))."  #(")
    call append(19,"module ".expand("%:r")."  #(")
    call append(20,")(")
    call append(21,");")
    call append(22,"")
    call append(23,"")
    call append(24,"")
    call append(25,"endmodule")
  echo
endfunction     

function SetLastModifiedTimes()
  let pos = getpos('.')
  let line = getline(16)
  let newtime = "// last modified : ".strftime("%Y-%m-%d %H:%M:%S")
  let repl = substitute(line,".*$",newtime,"g")
  let res = search("// last modified","w")
  if res
    call setline(16,repl)
  endif
    call setpos(".",pos)
endfunction

let g:my_function =1

autocmd BufNewFile,BufRead *.log setfiletype log


