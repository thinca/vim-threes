" Play Threes! in Vim!
" Version: 1.6
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:List = g:threes#vital.import('Data.List')

let s:DATA_VERSION = 2

let s:save_data = {
\   'records': [],
\ }

function! threes#record#clear() abort
  let s:save_data.records = []
endfunction

function! threes#record#load(file) abort
  if filereadable(a:file)
    let lines = readfile(a:file)
    let s:save_data = s:load_savedata(lines)
  else
    let s:save_data.records = []
  endif
endfunction

function! threes#record#save(file) abort
  let lines = [s:DATA_VERSION, string(threes#record#stats())] +
  \           map(copy(s:save_data.records), 'string(v:val)')
  call writefile(lines, a:file)
endfunction

function! threes#record#list() abort
  return copy(s:save_data.records)
endfunction

function! threes#record#best(n) abort
  let best = s:List.sort_by(copy(s:save_data.records), '-v:val.score')
  return len(best) <= a:n ? best : best[: a:n - 1]
endfunction

function! threes#record#add(threes) abort
  call add(s:save_data.records, threes#record#make(a:threes))
  unlet! s:stats
endfunction

function! threes#record#make(threes) abort
  return {
  \   'config': a:threes._config,
  \   'score': a:threes.total_score(),
  \   'highest_tile': a:threes.highest_tile(),
  \   'tiles': a:threes.tiles(),
  \   'seed': a:threes.seed(),
  \   'steps': a:threes.steps(),
  \   'finish': a:threes.is_gameover(),
  \   'date': localtime(),
  \ }
endfunction

function! threes#record#stats() abort
  if !exists('s:stats')
    let s:stats = s:make_stats(s:save_data.records)
  endif
  return s:stats
endfunction

function! s:make_stats(list) abort
  let score_list = map(copy(s:save_data.records), 'v:val.score')
  return {
  \   'top': max(score_list),
  \   'play_count': len(a:list),
  \   'average': s:sum(score_list) / len(a:list),
  \   'highest_tile': max(map(copy(s:save_data.records), 'v:val.highest_tile')),
  \ }
endfunction

function! s:sum(list) abort
  return empty(a:list) ? 0 : eval(join(a:list, '+'))
endfunction

function! s:load_savedata(lines) abort
  let ver = remove(a:lines, 0)
  let savedata = s:load_version_{ver}(a:lines)
  while ver != s:DATA_VERSION
    let savedata = s:migrate_version_{ver}_to_{ver + 1}(savedata)
    let ver += 1
  endwhile
  return savedata
endfunction

function! s:load_version_1(lines) abort
  call remove(a:lines, 0)  " stats
  return {
  \   'records': map(a:lines, 'eval(v:val)'),
  \ }
endfunction
let s:load_version_2 = function('s:load_version_1')

function! s:migrate_version_1_to_2(savedata) abort
  let config = {
  \   'width': 4,
  \   'height': 4,
  \   'origin_numbers': [1, 2],
  \   'init_count': 9,
  \   'init_higher_tile': 0,
  \   'large_num_limit': 3,
  \   'large_num_odds': 21,
  \   'hide_large_next_tile': 1,
  \   'large_next_tile_count': 1,
  \ }
  for record in a:savedata.records
    let record.config = deepcopy(config)
  endfor
  return a:savedata
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
