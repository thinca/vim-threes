" Play Threes! in Vim!
" Version: 1.4
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:DATA_VERSION = 1

let s:records = []

function! threes#record#clear()
  let s:records = []
endfunction

function! threes#record#load(file)
  if filereadable(a:file)
    let lines = readfile(a:file)
    if remove(lines, 0) != s:DATA_VERSION
      " TODO: Migration
    endif
    let [s:stat; s:records] = map(lines, 'eval(v:val)')
  else
    let s:records = []
  endif
endfunction

function! threes#record#save(file)
  let lines = [s:DATA_VERSION, string(threes#record#stats())] +
  \           map(copy(s:records), 'string(v:val)')
  call writefile(lines, a:file)
endfunction

function! threes#record#list()
  return copy(s:records)
endfunction

function! threes#record#add(threes)
  call add(s:records, threes#record#make(a:threes))
  unlet! s:stats
endfunction

function! threes#record#make(threes)
  return {
  \   'score': a:threes.total_score(),
  \   'highest_tile': a:threes.highest_tile(),
  \   'tiles': a:threes.tiles(),
  \   'seed': a:threes.seed(),
  \   'steps': a:threes.steps(),
  \   'date': localtime(),
  \ }
endfunction

function! threes#record#stats()
  if !exists('s:stats')
    let s:stats = s:make_stats(s:records)
  endif
  return s:stats
endfunction

function! s:make_stats(list)
  let score_list = map(copy(s:records), 'v:val.score')
  return {
  \   'top': max(score_list),
  \   'play_count': len(a:list),
  \   'average': s:sum(score_list) / len(a:list),
  \   'highest_tile': max(map(copy(s:records), 'v:val.highest_tile')),
  \ }
endfunction

function! s:sum(list)
  return eval(join(a:list, '+'))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
