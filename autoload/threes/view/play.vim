" Play Threes! in Vim!
" Version: 1.5
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! threes#view#play#open()
  call s:define_keymappings()
  call s:init_buffer()
  if exists('s:current_threes') && !s:current_threes.is_gameover()
    let b:threes = s:current_threes
    call b:threes.render()
  else
    let b:threes = threes#new(s:setting_from_options())
    let s:current_threes = b:threes
    call b:threes.start()
  endif
endfunction

function! s:init_buffer()
  setlocal readonly nomodifiable buftype=nofile bufhidden=wipe
  setlocal nonumber norelativenumber nowrap nolist
  setlocal nocursorline nocursorcolumn colorcolumn=
  setlocal conceallevel=3 concealcursor+=n
  setlocal filetype=threes
  let b:threes_cursor = s:current_cursor()
  augroup plugin-threes-cursor
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:hide_cursor()
    autocmd BufLeave <buffer> execute b:threes_cursor
  augroup END
  call s:hide_cursor()
endfunction

function! s:define_keymappings()
  noremap <buffer> <silent> <Plug>(threes-move-left)
  \       :<C-u>call b:threes.next(-1, 0).render()<CR>
  noremap <buffer> <silent> <Plug>(threes-move-down)
  \       :<C-u>call b:threes.next(0, 1).render()<CR>
  noremap <buffer> <silent> <Plug>(threes-move-up)
  \       :<C-u>call b:threes.next(0, -1).render()<CR>
  noremap <buffer> <silent> <Plug>(threes-move-right)
  \       :<C-u>call b:threes.next(1, 0).render()<CR>
  noremap <buffer> <silent> <Plug>(threes-restart)
  \       :<C-u>call b:threes.restart(<SID>setting_from_options())<CR>
  noremap <buffer> <silent> <Plug>(threes-quit)
  \       :<C-u>call b:threes.quit()<CR>
  noremap <buffer> <silent> <Plug>(threes-redraw)
  \       :<C-u>call b:threes.render()<CR>
  noremap <buffer> <silent> <Plug>(threes-tweet)
  \       :<C-u>call b:threes.tweet()<CR>

  map <buffer> h <Plug>(threes-move-left)
  map <buffer> j <Plug>(threes-move-down)
  map <buffer> k <Plug>(threes-move-up)
  map <buffer> l <Plug>(threes-move-right)
  map <buffer> r <Plug>(threes-restart)
  map <buffer> q <Plug>(threes-quit)
  map <buffer> <C-l> <Plug>(threes-redraw)
  map <buffer> t <Plug>(threes-tweet)
endfunction

function! s:current_cursor()
  if !has('gui_running')
    return 'let &t_ve = ' . string(&t_ve)
  endif
  redir => cursor
  silent! highlight Cursor
  redir END
  if cursor !~# 'xxx'
    return ''
  endif
  return 'highlight Cursor ' .
  \      substitute(matchstr(cursor, 'xxx\zs.*'), "\n", ' ', 'g')
endfunction

function! s:hide_cursor()
  if has('gui_running')
    highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
  else
    set t_ve=
  endif
endfunction

function! s:setting_from_options()
  let setting = a:0 ? copy(a:1) : {}
  if g:threes#start_with_higher_tile
    let highest_tile = threes#record#stats().highest_tile
    let higher_tile = highest_tile / 8
    if 3 < higher_tile  " XXX: 3 is base number
      let setting.init_higher_tile = higher_tile
    endif
  endif
  return setting
  return threes#new(setting)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
