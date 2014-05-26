" Play Threes! in Vim!
" Version: 1.4
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! threes#view#read(path)
  let page = matchstr(a:path, '^threes://\zs.*')
  call threes#view#{page}#open()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
