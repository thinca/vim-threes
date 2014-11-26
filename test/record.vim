let s:suite = themis#suite('threes#record')
call themis#helper('command').with(themis#helper('assert'))

let g:threes#data_directory = ''

function! s:suite.before_each() abort
  let self.t = threes#new()
  call self.t.new_game()
endfunction

function! s:suite.make() abort
  let self.t._state.tiles = [
  \   [3,   2,  3,   6],
  \   [48, 12,  192, 2],
  \   [96, 24,  3,   6],
  \   [48, 12,  1,   1],
  \ ]
  let record = threes#record#make(self.t)

  Assert Equals(record.score, 3564)
  Assert Equals(record.tiles, [3 ,2 ,3 ,6 ,48 ,12 ,192 ,2 ,96 ,24 ,3 ,6 ,48 ,12 ,1 ,1])
  Assert Equals(record.highest_tile, 192)
endfunction

function! s:suite.stat() abort
  call threes#record#clear()
  let self.t._state.tiles = [
  \   [3,   2,  3,   6],
  \   [48, 12,  192, 2],
  \   [96, 24,  3,   6],
  \   [48, 12,  1,   1],
  \ ]
  call threes#record#add(self.t)

  let self.t._state.tiles = [
  \   [12, 2, 24, 48],
  \   [3, 12, 1, 6],
  \   [1, 6, 12, 2],
  \   [6, 3, 6, 12],
  \ ]
  call threes#record#add(self.t)

  let self.t._state.tiles = [
  \   [1, 6, 24, 3],
  \   [12, 2, 3, 12],
  \   [3, 12, 6, 2],
  \   [1, 6, 3, 2],
  \ ]
  call threes#record#add(self.t)

  let stats = threes#record#stats()
  Assert Equals(stats.top, 3564)
  Assert Equals(stats.play_count, 3)
  Assert Equals(stats.average, 1413)
  Assert Equals(stats.highest_tile, 192)
endfunction

function! s:suite.save_and_load() abort
endfunction
