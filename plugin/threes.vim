" Play Threes! in Vim!
" Version: 1.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('g:loaded_threes')
  finish
endif
let g:loaded_threes = 1

let s:save_cpo = &cpo
set cpo&vim

command! ThreesStart call threes#start()

let &cpo = s:save_cpo
unlet s:save_cpo
