" Play Threes! in Vim!
" Version: 1.5
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:Renderer = {}

function! threes#renderer#new(...)
  let renderer = deepcopy(s:Renderer)
  call call(renderer.init, a:000, renderer)
  return renderer
endfunction

function! s:Renderer.init(game)
  let self._game = a:game
  let self._tile_width = 6
  let self._tile_height = 3
  let self._tile_images = [{}, {}]
  let self._chars = {}
  let self._chars.horizontal = '-'
  let self._chars.vertical = '|'
  let self._chars.cross = '+'

  call self.reset_tile_animate()

  let vwidth = strwidth(self._chars.vertical)
  let self._canvas_width =
  \   (self._tile_width + vwidth) * (a:game.width() + 2) + vwidth
  let self._canvas = threes#canvas#new(self._canvas_width, 0)
  let self._frame = self.make_frame(a:game.width(), a:game.height())
endfunction

function! s:Renderer.render_game()
  let canvas = self._canvas
  let game = self._game
  call canvas.resize(-1, 0)
  call canvas.reset_origin()

  " Render gameover message
  let gameover = game.is_gameover()
  if gameover
    call canvas.draw_center('Out of moves!', 0)
  endif

  " Render next
  call canvas.set_origin(0, 2)
  call self.render_next(canvas)

  " Render board
  call canvas.set_origin(self._tile_width, canvas.height())
  call self.render_board(canvas)
  call canvas.set_origin(0, canvas.origin_y())
  call canvas.reset_origin()

  if gameover
    " Render score
    let score_line = 'score: ' . game.total_score()
    call canvas.draw_center(score_line, canvas.height() + 1)

    call canvas.draw_center('', canvas.height() + 1)
    if maparg('t', 'n') ==# '<Plug>(threes-tweet)'
      let mes = 'Press "t" to tweet your score!'
      call canvas.draw_center(mes, canvas.height())
    endif

    if maparg('r', 'n') ==# '<Plug>(threes-restart)'
      let mes = 'Press "r" to restart game'
      call canvas.draw_center(mes, canvas.height())
    endif

    if maparg('Q', 'n') ==# '<Plug>(threes-quit)'
      let mes = 'Press "Q" to quit game'
      call canvas.draw_center(mes, canvas.height())
    endif
  endif
  return map(copy(canvas._field), 'substitute(v:val, "\\s\\+$", "", "")')
endfunction

function! s:Renderer.render_next(canvas)
  let tile_width = self._tile_width
  let vertical = self._chars.vertical
  let color = self.tile_color_char(self._game.next_tile())
  let next_tile = s:centerize(self.next_tile_str(), tile_width, color)
  let line = self.make_horizontal(tile_width)
  call a:canvas.draw_center('NEXT', 0)
  call a:canvas.draw_center(line, 1)
  call a:canvas.draw_center(vertical . next_tile . vertical, 2)
  call a:canvas.draw_center(line, 3)
endfunction

function! s:Renderer.render_board(canvas)
  let game = self._game
  call a:canvas.draw(self._frame, 0, 0)
  let highest = game.highest_tile()
  if highest <= game.base_number()
    let highest = -1
  endif

  call self.render_tiles(a:canvas, game.tile_list(self._moved_tile),
  \                      highest, 0, 0)
  call self.render_tiles(a:canvas, self._moved_tile, highest,
  \                      self._tile_dx, self._tile_dy)
endfunction

function! s:Renderer.render_tiles(canvas, tiles, highest, dx, dy)
  for [x, y, tile] in a:tiles
    let cx = x * (self._tile_width + 1) + 1 + a:dx
    let cy = y * (self._tile_height + 1) + 1 + a:dy
    let tile_image = self.get_tile(tile, tile == a:highest)
    call a:canvas.draw(tile_image, cx, cy)
  endfor
endfunction

function! s:Renderer.set_tile_animate(dx, dy)
  let self._tile_dx = a:dx
  let self._tile_dy = a:dy
endfunction

function! s:Renderer.set_moved_tile(moved)
  let self._moved_tile = a:moved
endfunction

function! s:Renderer.reset_tile_animate()
  let self._moved_tile = []
  let self._tile_dx = 0
  let self._tile_dy = 0
endfunction

function! s:Renderer.make_frame(x, y)
  let tile_width = self._tile_width
  let tile_height = self._tile_height
  let c = self._chars

  let tile_h = c.cross . repeat(c.horizontal, tile_width)
  let h = repeat(tile_h, self._game.width()) . c.cross
  let tile_v = c.vertical . repeat(' ', tile_width)
  let v = repeat(tile_v, self._game.width()) . c.vertical
  let tile_line = [h] + repeat([v], tile_height)
  let board = repeat(tile_line, self._game.height()) + [h]
  return board
endfunction

function! s:Renderer.make_horizontal(width)
  let c = self._chars
  return c.cross . repeat(c.horizontal, a:width) . c.cross
endfunction

function! s:Renderer.get_tile(tile, is_highest)
  let images = self._tile_images[!!a:is_highest]
  if !has_key(images, a:tile)
    let images[a:tile] = self.make_tile(a:tile, a:is_highest)
  endif
  return images[a:tile]
endfunction

function! s:Renderer.make_tile(tile, is_highest)
  let tile_width = self._tile_width
  let tile_height = self._tile_height

  let color = a:is_highest ? '*' : self.tile_color_char(a:tile)
  let tile_str = a:tile == 0 ? '' : a:tile

  let line_tiles = []
  for n in range(tile_height)
    if n == tile_height / 2
      let line_tiles += [s:centerize(tile_str, tile_width, color)]
    else
      let line_tiles += [repeat(color, tile_width)]
    endif
  endfor
  return line_tiles
endfunction

function! s:Renderer.next_tile_str()
  let next = self._game.next_tile()
  return self._game.base_number() < next ? '+' : ''
endfunction

function! s:Renderer.tile_color_char(tile)
  let colors = ['_', ' ', '.', ',']
  return colors[index([0] + self._game._setting.origin_numbers, a:tile) + 1]
endfunction

function! s:centerize(str, width, ...)
  let char = a:0 ? a:1 : ' '
  let w = strwidth(a:str)
  let padding = a:width - w
  let left = padding / 2
  let right = padding - left
  return repeat(char, left) . a:str . repeat(char, right)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
