" key mappings

:nnoremap ; :
:nnoremap J :m<Space>.+1<CR>==
:nnoremap K :m<Space>.-2<CR>==
:nnoremap < <<
:nnoremap > >> 
:nnoremap <Esc> :noh<CR>

"==========================================================

:inoremap jk <esc>

"==========================================================

:vnoremap < <gv
:vnoremap > >gv

" this not work on vsvim
":vnoremap J :m<Space>'>+1<CR>gv-gv 
":vnoremap K :m<Space>'<-2<CR>gv-gv 

" this work fine
" more info refer to https://github.com/VsVim/VsVim/issues/2446
:vnoremap J dpV'] 
:vnoremap K d-PV'] 

:vnoremap p "_dP

"==========================================================
" options

:set vsvimcaret=70
:set number relativenumber
:set clipboard=unnamed
