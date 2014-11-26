" Play Threes! in Vim!
" Version: 1.6
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! threes#view#record#open() abort
  call s:draw()
endfunction

function! s:init_buffer() abort
  setlocal readonly nomodifiable buftype=nofile bufhidden=wipe
  setlocal nonumber norelativenumber nowrap nolist
  setlocal nocursorline nocursorcolumn colorcolumn=
endfunction

function! s:draw() abort
  setlocal noreadonly modifiable
  let record_list = threes#record#best(10)
  let lines = [
  \   'Rank    Score  Date',
  \   '-------------------------------',
  \ ]
  let lines += map(record_list, 's:make_record_line(v:key, v:val)')
  silent % delete _
  silent put =lines
  silent 1 delete _
  setlocal readonly nomodifiable
  redraw
endfunction

function! s:make_record_line(index, record) abort
  return printf(' %2d.   %6d  %s',
  \   a:index + 1,
  \   a:record.score,
  \   strftime('%Y/%m/%d %H:%M', a:record.date)
  \ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
