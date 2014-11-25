" Play Threes! in Vim!
" Version: 1.5
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:List = g:threes#vital.import('Data.List')

let s:DATA_VERSION = 1

let s:save_data = {
\   'records': [],
\ }

function! threes#record#clear()
  let s:save_data.records = []
endfunction

function! threes#record#load(file)
  if filereadable(a:file)
    let lines = readfile(a:file)
    if remove(lines, 0) != s:DATA_VERSION
      " TODO: Migration
    endif
    let [s:stat; s:save_data.records] = map(lines, 'eval(v:val)')
  else
    let s:save_data.records = []
  endif
endfunction

function! threes#record#save(file)
  let lines = [s:DATA_VERSION, string(threes#record#stats())] +
  \           map(copy(s:save_data.records), 'string(v:val)')
  call writefile(lines, a:file)
endfunction

function! threes#record#list()
  return copy(s:save_data.records)
endfunction

function! threes#record#best(n)
  let best = s:List.sort_by(copy(s:save_data.records), '-v:val.score')
  return len(best) <= a:n ? best : best[: a:n - 1]
endfunction

function! threes#record#add(threes)
  call add(s:save_data.records, threes#record#make(a:threes))
  unlet! s:stats
endfunction

function! threes#record#make(threes)
  return {
  \   'score': a:threes.total_score(),
  \   'highest_tile': a:threes.highest_tile(),
  \   'tiles': a:threes.tiles(),
  \   'seed': a:threes.seed(),
  \   'steps': a:threes.steps(),
  \   'finish': a:threes.is_gameover(),
  \   'date': localtime(),
  \ }
endfunction

function! threes#record#stats()
  if !exists('s:stats')
    let s:stats = s:make_stats(s:save_data.records)
  endif
  return s:stats
endfunction

function! s:make_stats(list)
  let score_list = map(copy(s:save_data.records), 'v:val.score')
  return {
  \   'top': max(score_list),
  \   'play_count': len(a:list),
  \   'average': s:sum(score_list) / len(a:list),
  \   'highest_tile': max(map(copy(s:save_data.records), 'v:val.highest_tile')),
  \ }
endfunction

function! s:sum(list)
  return eval(join(a:list, '+'))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
