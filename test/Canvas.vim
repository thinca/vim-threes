let s:suite = themis#suite('Canvas')
call themis#helper('command').with(themis#helper('assert'))

function! s:suite.field() abort
  let canvas = threes#canvas#new(10, 20)
  Assert Equals(canvas.width(), 10)
  Assert Equals(len(canvas._field[0]), 10)
  Assert Equals(canvas.height(), 20)
  Assert Equals(len(canvas._field), 20)
endfunction

function! s:suite.draw() abort
  let canvas = threes#canvas#new([
  \   '+------+',
  \   '|      |',
  \   '|      |',
  \   '|      |',
  \   '+------+',
  \ ])
  let image = [
  \   '......',
  \   '.768..',
  \   '......',
  \ ]
  let expect = [
  \   '+------+',
  \   '|......|',
  \   '|.768..|',
  \   '|......|',
  \   '+------+',
  \ ]
  call canvas.draw(image, 1, 1)
  Assert Equals(canvas._field, expect)

  let expect2 = [
  \   '+------+ ',
  \   '|......| ',
  \   '|.768..| ',
  \   '|........',
  \   '+--.768..',
  \   '   ......',
  \ ]
  call canvas.draw(image, 3, 3)
  Assert Equals(canvas._field, expect2)
endfunction

function! s:suite.draw_center() abort
  let canvas = threes#canvas#new([
  \   '+------+',
  \   '|      |',
  \   '|      |',
  \   '|      |',
  \   '+------+',
  \ ])
  let image = [
  \   '......',
  \   '.768..',
  \   '......',
  \ ]
  let expect = [
  \   '+------+',
  \   '|......|',
  \   '|.768..|',
  \   '|......|',
  \   '+------+',
  \ ]
  call canvas.draw_center(image, 1)
  Assert Equals(canvas._field, expect)
endfunction

function! s:suite.extend() abort
  let canvas = threes#canvas#new()

  call canvas.extend(5, 5)
  Assert Equals(canvas.width(), 5)
  Assert Equals(canvas.height(), 5)

  call canvas.extend(3, 10)
  Assert Equals(canvas.width(), 5)
  Assert Equals(canvas.height(), 10)
endfunction

function! s:suite.resize() abort
  let canvas = threes#canvas#new(10, 10)

  call canvas.resize(5, 5)
  Assert Equals(canvas.width(), 5)
  Assert Equals(canvas.height(), 5)

  call canvas.resize(-1, 0)
  Assert Equals(canvas.width(), 5)
  Assert Equals(canvas.height(), 0)
endfunction
