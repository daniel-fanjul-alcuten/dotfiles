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

" git {{{
aug gitconfig_filetype
  au Filetype gitconfig setl noet
aug end
" vim-fugitive {{{
nnoremap <Leader>gb :Gblame<cr>
nnoremap <Leader>gc :Gcommit -v<cr>
nnoremap <Leader>gca :Gcommit -v -a<cr>
nnoremap <Leader>gcaa :Gcommit -a -m.<cr>
nnoremap <Leader>gcc :Gcommit -m.<cr>
nnoremap <Leader>gd :Gdiff<cr>
nnoremap <Leader>gpp :Git push<cr>
nnoremap <Leader>gpm :Git pushm<cr>
nnoremap <Leader>gpmf :Git pushmf<cr>
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
  au BufWrite *.go silent !~/lib/go/bin/gotags -L <(find . -type f -name \*.go) > tags
aug end
com! -nargs=1 -complete=dir Oar :ar <args>/*.go
com! -nargs=1 -complete=dir Oargl :argl <args>/*.go
com! -nargs=1 -complete=dir Ocd :cd <args> | :ar *.go
com! -nargs=1 -complete=dir Olcd :lcd <args> | :argl *.go
com! -nargs=1 -complete=dir Otabe :tabe | :lcd <args> | :argl *.go
nnoremap <Leader>gi :GoImports<cr>
nnoremap <Leader>gl :GoLint<cr>
nnoremap <Leader>gv :GoVet<cr>
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
