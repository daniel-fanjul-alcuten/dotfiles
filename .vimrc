" general {{{
se ts=2 sts=2 et nojs
se sr sw=2 si
se sm nu rnu
se hid aw
se is ic scs hls
se list lcs=tab:→\ ,trail:·
se ml mls=5
sy on
filet plugin indent on
" }}}

" vim {{{
aug vim_filetype
  au Filetype vim setl fdm=marker fdc=2
aug end
" .vimrc {{{
nnoremap <Leader>ev :vsplit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC<cr>
" }}}
" }}}

" gpg {{{
let g:GPGExecutable='gpg2'
let g:GPGPreferSign=1
" }}}

" git {{{
aug gitconfig_filetype
  au Filetype gitconfig setl noet
aug end
" vim-fugitive {{{
nnoremap <Leader>gd :Gdiff<cr>
nnoremap <Leader>gr :Gread<cr>
nnoremap <Leader>gs :Gstatus<cr>
nnoremap <Leader>gw :Gwrite<cr>
nnoremap git :Git
" }}}
" }}}

" go {{{
aug go_filetype
  au!
  au Filetype go setl nolist
  au Filetype go setl cc=80
  au Filetype go setl fdm=syntax fdc=3
  au Filetype go setl makeprg=go\ test\ ./...
  au Filetype go nnoremap <buffer> <Leader>f :GoFmt<CR>
  au Filetype go nnoremap <buffer> <Leader>t :GoTest<CR>
aug end
com! -nargs=1 -complete=dir Gg :argl <args>/*.go
com! -nargs=1 -complete=dir Tg :tabe | :Gg <args>
nnoremap <Leader>i :GoImports<cr>
nnoremap <Leader>l :GoLint<cr>
nnoremap <Leader>v :GoVet<cr>
" }}}

" ruby {{{
aug ruby_filetype
  au!
  au Filetype ruby setl cc=80
  au Filetype ruby setl fdm=syntax fdc=3
aug end
" }}}

" json {{{
aug json_filetype
  au!
  au Filetype json nnoremap <buffer> <Leader>j :%!python -mjson.tool<CR>
  au BufRead,BufNewFile *.json set ft=json
aug end
" }}}

" python {{{
aug python_filetype
  au!
  au Filetype python setl ts=4 sts=4 sw=4
aug end
" }}}

" key mappings {{{
nnoremap <Leader>m :make<CR>
" }}}

" pathogen {{{
cal pathogen#infect()
" }}}

" solarized {{{
se background=dark
colo solarized
set t_Co=16
" }}}

" syntastic {{{
let g:syntastic_auto_jump=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=0
let g:syntastic_go_checkers=['go', 'govet']
let g:syntastic_ruby_checkers=['mri', 'rubocop']
let g:syntastic_python_checkers=['python', 'pep8', 'flake8']
nnoremap <Leader>sc :SyntasticCheck<CR>
nnoremap <Leader>st :SyntasticToggleMode<CR>
nnoremap <Leader>sr :SyntasticReset<CR>
" }}}
