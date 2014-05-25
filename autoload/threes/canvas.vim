" Play Threes! in Vim!
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

" A simple canvas system.  This treats ascii character only.
let s:Canvas = {}

function! s:to_canvas(...)
  if type(a:1) == type({}) && has_key(a:1, '_field')
    return a:1
  endif
  return call('threes#canvas#new', a:000)
endfunction

function! threes#canvas#new(...)
  let canvas = deepcopy(s:Canvas)
  call call(canvas.init, a:000, canvas)
  return canvas
endfunction

function! s:Canvas.init(...)
  let [self._width, self._height] = [0, 0]
  if a:0 == 0
    let lines = []
  elseif a:0 == 2 && type(a:1) == type(0) && type(a:2) == type(0)
    let lines = []
    let [width, height] = a:000
  elseif type(a:1) == type('')
    let lines = split(a:1, "\n")
  elseif type(a:1) == type([])
    let lines = a:1
  elseif type(a:1) == type({}) && has_key(a:1, '_field')
    let lines = copy(a:1._field)
  else
    throw 'Canvas: Invalid argument.'
  endif
  let self._field = lines
  if exists('width')
    call self.extend(width, height)
  else
    let self._width = max(map(copy(self._field), 'strwidth(v:val)'))
    let self._height = len(self._field)
  endif
  call self.reset_origin()
endfunction

function! s:Canvas.clear()
  return map(self._field, 'substitute(v:val, ".", " ", "g")')
endfunction

function! s:Canvas.width()
  return self._width
endfunction

function! s:Canvas.height()
  return self._height
endfunction

function! s:Canvas.reset_origin()
  call self.set_origin(0, 0)
endfunction

function! s:Canvas.origin_x()
  return self._origin_x
endfunction

function! s:Canvas.origin_y()
  return self._origin_y
endfunction

function! s:Canvas.set_origin(x, y)
  let self._origin_x = a:x
  let self._origin_y = a:y
endfunction

function! s:Canvas.draw(image, x, y)
  let target = s:to_canvas(a:image)
  let [x, y] = [a:x + self._origin_x, a:y + self._origin_y]
  call self.extend(x + target.width(), y + target.height())
  for n in range(target.height())
    let line = self._field[y + n]
    let self._field[y + n] =
    \   s:head(line, x) .
    \   target._field[n] .
    \   line[x + target.width() :]
  endfor
endfunction

function! s:Canvas.draw_center(image, y)
  let target = s:to_canvas(a:image)
  call self.draw(a:image, (self.width() - target.width()) / 2, a:y)
endfunction

function! s:Canvas.extend(width, height)
  if self.width() < a:width
    call map(self._field, 'v:val . repeat(" ", a:width - len(v:val))')
    let self._width = a:width
  endif
  if self.height() < a:height
    let line = repeat(' ', self.width())
    let self._field += repeat([line], a:height - self.height())
    let self._height = a:height
  endif
endfunction

function! s:Canvas.resize(width, height)
  call self.extend(a:width, a:height)
  if 0 <= a:height && a:height < self.height()
    let self._field = s:head(self._field, a:height)
    let self._height = a:height
  endif
  if 0 <= a:width && a:width < self.width()
    let expr = a:width == 0 ? '""' : 'v:val[: a:width - 1]'
    call map(self._field, expr)
    let self._width = a:width
  endif
endfunction

function! s:head(x, size)
  return a:size != 0           ? a:x[: a:size - 1] :
  \      type(a:x) == type('') ? '' : []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
