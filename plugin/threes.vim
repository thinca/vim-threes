" Play Threes! in Vim!
" Version: 1.6.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_threes')
  finish
endif
let g:loaded_threes = 1

let s:save_cpo = &cpo
set cpo&vim

command! ThreesStart call threes#start()
command! ThreesShowRecord call threes#show_record()

augroup plugin-threes
  autocmd!
  autocmd BufReadCmd threes://* call threes#view#read(expand('<amatch>'))
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
