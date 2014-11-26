let s:suite = themis#suite('Threes object')
call themis#helper('command').with(themis#helper('assert'))

function! s:suite.before_each() abort
  let self.t = threes#new()
  call self.t.new_game()
endfunction

function! s:suite.tiles() abort
  let t = self.t
  Assert Equals(t.width(), 4)
  Assert Equals(t.height(), 4)
  Assert NotSame(t._state.tiles[0], t._state.tiles[1])
endfunction

function! s:suite.tile_list() abort
  let t = self.t
  let t._state.next = 0
  let t._state.tiles = [
  \   [0, 1, 2, 0],
  \   [1, 2, 0, 0],
  \   [3, 3, 3, 3],
  \   [6, 3, 3, 3],
  \ ]
  let expect = [
  \   [0, 1, 1],
  \   [0, 2, 3],
  \   [0, 3, 6],
  \   [1, 0, 1],
  \   [1, 1, 2],
  \   [1, 2, 3],
  \   [1, 3, 3],
  \   [2, 0, 2],
  \   [2, 2, 3],
  \   [2, 3, 3],
  \   [3, 2, 3],
  \   [3, 3, 3],
  \ ]
  Assert Equals(t.tile_list(), expect)

  let exclude_list = []
  for n in range(5)
    let exclude_list += [remove(expect, 3)]
  endfor
  Assert Equals(t.tile_list(exclude_list), expect)

  let exclude_list += [[-1, 3, 1]]
  Assert Equals(t.tile_list(exclude_list), expect)
endfunction

function! s:suite.append_tile() abort
  let t = self.t
  Assert Equals(t.append_tile(1,  2), 3)
  Assert Equals(t.append_tile(2,  2), 0)
  Assert Equals(t.append_tile(3,  3), 6)
  Assert Equals(t.append_tile(1,  0), 1)
  Assert Equals(t.append_tile(2,  0), 2)
  Assert Equals(t.append_tile(12, 0), 12)
  Assert Equals(t.append_tile(0,  1), 0)
endfunction

function! s:suite.move() abort
  let t = self.t
  let t._state.next = 0
  let t._state.tiles = [
  \   [0, 1, 2, 0],
  \   [1, 2, 0, 0],
  \   [3, 3, 3, 3],
  \   [6, 3, 3, 3],
  \ ]
  let expect_left = [
  \   [1, 2, 0, 0],
  \   [3, 0, 0, 0],
  \   [6, 3, 3, 0],
  \   [6, 6, 3, 0],
  \ ]
  let expect_down = [
  \   [0, 0, 0, 0],
  \   [1, 1, 2, 0],
  \   [3, 2, 0, 0],
  \   [6, 6, 6, 6],
  \ ]
  let expect_up = [
  \   [1, 3, 2, 0],
  \   [3, 3, 3, 3],
  \   [6, 3, 3, 3],
  \   [0, 0, 0, 0],
  \ ]
  let expect_right = [
  \   [0, 0, 1, 2],
  \   [0, 1, 2, 0],
  \   [0, 3, 3, 6],
  \   [0, 6, 3, 6],
  \ ]

  Assert Equals(t.move(-1, 0).tiles, expect_left)
  Assert Equals(t.move(0, 1).tiles, expect_down)
  Assert Equals(t.move(0, -1).tiles, expect_up)
  Assert Equals(t.move(1, 0).tiles, expect_right)
endfunction

function! s:suite.is_gameover() abort
  let t = self.t
  let t._state.next_tile = 2
  let t._state.deck = [2, 2]
  let t._state.tiles = [
  \   [3, 1, 1, 1],
  \   [2, 3, 1, 1],
  \   [2, 2, 3, 1],
  \   [2, 1, 2, 0],
  \ ]
  Assert False(t.is_gameover())
  call t.next(1, 0)
  Assert False(t.is_gameover())
  call t.next(1, 0)
  Assert True(t.is_gameover())
endfunction

function! s:suite.exp() abort
  let t = self.t
  Assert Equals(t.exp(1), -1)
  Assert Equals(t.exp(2), -1)
  Assert Equals(t.exp(3), 0)
  Assert Equals(t.exp(6), 1)
  Assert Equals(t.exp(12), 2)
  Assert Equals(t.exp(24), 3)
  Assert Equals(t.exp(48), 4)
  Assert Equals(t.exp(96), 5)
  Assert Equals(t.exp(192), 6)
  Assert Equals(t.exp(384), 7)
  Assert Equals(t.exp(768), 8)
  Assert Equals(t.exp(1536), 9)
  Assert Equals(t.exp(3072), 10)
  Assert Equals(t.exp(6144), 11)
endfunction

function! s:suite.score() abort
  let t = self.t
  Assert Equals(t.score(1), 0)
  Assert Equals(t.score(2), 0)
  Assert Equals(t.score(3), 3)
  Assert Equals(t.score(6), 9)
  Assert Equals(t.score(12), 27)
  Assert Equals(t.score(24), 81)
  Assert Equals(t.score(48), 243)
  Assert Equals(t.score(96), 729)
  Assert Equals(t.score(192), 2187)
  Assert Equals(t.score(384), 6561)
  Assert Equals(t.score(768), 19683)
  Assert Equals(t.score(1536), 59049)
  Assert Equals(t.score(3072), 177147)
  Assert Equals(t.score(6144), 531441)
endfunction

function! s:suite.total_score() abort
  let t = self.t
  let t._state.tiles = [
  \   [3, 1, 1, 1],
  \   [2, 3, 1, 1],
  \   [2, 2, 3, 1],
  \   [2, 2, 2, 3],
  \ ]
  Assert Equals(t.total_score(), 12)
endfunction

function! s:suite.steps() abort
  let t = self.t
  let t._state.next = 0
  " Movable to right
  let t._state.tiles = [
  \   [0, 0, 0, 0],
  \   [1, 0, 0, 0],
  \   [3, 0, 0, 0],
  \   [6, 0, 0, 0],
  \ ]
  Assert Equals(t._state.steps, [])
  call t.next(1, 0)
  Assert Equals(t._state.steps, [1])
  call t.next(1, 0)
  Assert Equals(t._state.steps, [1, 1])
  call t.next(1, 0)
  Assert Equals(t._state.steps, [1, 1, 1])
endfunction
