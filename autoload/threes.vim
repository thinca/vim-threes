" Play Threes! in Vim!
" Version: 1.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('threes')
let s:Random = s:V.import('Random.Xor128')
call s:Random.srand()
let s:List = s:V.import('Data.List')


let s:tweet_template = 'I just scored %s in threes.vim! https://github.com/thinca/vim-threes #threesvim'

let s:default_setting = {
\   'width': 4,
\   'height': 4,
\   'origin_numbers': [1, 2],
\   'init_count': 9,
\   'large_num_limit': 3,
\   'large_num_odds': 21,
\ }

let s:Threes = {}

function! s:Threes.init(setting)
  let self._setting = deepcopy(a:setting)

  let self._base_number = s:sum(self._setting.origin_numbers)
  let origin_num = (self.width() + self.height()) / 2
  let self._origin_deck =
  \        repeat(self._setting.origin_numbers, origin_num) +
  \        repeat([self.base_number()], origin_num)
  let self._renderer = s:Renderer_new(self)
endfunction

function! s:Threes.reset()
  let self._state = {}
  let self._state.tiles =
  \        map(range(self.width()), 'repeat([0], self.height())')
  let self._state.deck = []
  let self._state.tick = 0
endfunction

function! s:Threes.width()
  return self._setting.width
endfunction

function! s:Threes.height()
  return self._setting.height
endfunction

function! s:Threes.base_number()
  return self._base_number
endfunction

function! s:Threes.get_tile(x, y)
  return self._state.tiles[a:y][a:x]
endfunction

function! s:Threes.set_tile(x, y, tile)
  let self._state.tiles[a:y][a:x] = a:tile
endfunction

function! s:Threes.tiles()
  return s:List.flatten(self._state.tiles)
endfunction

function! s:Threes.tile_list(...)
  let list = []
  let exclude_list = a:0 ? a:1 : []

  let tiles = deepcopy(self._state.tiles)
  for [x, y, tile] in exclude_list
    if 0 <= x && 0 <= y && y < len(tiles) && x < len(tiles[y])
      let tiles[y][x] = 0
    endif
  endfor
  for x in range(self.width())
    for y in range(self.height())
      let tile = tiles[y][x]
      if tile != 0
        let list += [[x, y, tile]]
      endif
    endfor
  endfor
  return list
endfunction

function! s:Threes.next_tile()
  return self._state.next_tile
endfunction

function! s:Threes.highest_tile()
  return max(self.tiles())
endfunction

function! s:Threes.is_origin(tile)
  return s:List.has(self._setting.origin_numbers, a:tile)
endfunction

function! s:Threes.append_tile(from, to)
  if a:to == 0 ||
  \   (a:to == a:from ? self.base_number() <= a:to
  \                   : self.is_origin(a:to) && self.is_origin(a:from))
    return a:to + a:from
  endif
  return 0
endfunction

function! s:Threes.is_gameover()
  if s:List.has(self.tiles(), 0)
    return 0
  endif
  for [x, y] in [[-1, 0], [1, 0], [0, -1], [0, 1]]
    if !empty(self.move(x, y).moved)
      return 0
    endif
  endfor
  return 1
endfunction

function! s:Threes.new_game()
  call self.reset()
  let tile_count = self.width() * self.height()
  let random_tiles = s:shuffle(range(tile_count))
  let init_tiles = random_tiles[: self._setting.init_count - 1]
  for pos in init_tiles
    let x = pos % self.width()
    let y = pos / self.height()
    call self.set_tile(x, y, self.random_tile())
  endfor
  let self._state.next_tile = self.random_tile()
endfunction

function! s:Threes.start()
  call self.new_game()
  call self.render()
endfunction

function! s:Threes.move(dx, dy)
  let tiles = deepcopy(self._state.tiles)
  let moved = []
  let xrange = range(self.width())
  let yrange = range(self.height())
  if a:dx
    if 0 < a:dx
      call reverse(xrange)
    endif
    call remove(xrange, 0)
  elseif a:dy
    if 0 < a:dy
      call reverse(yrange)
    endif
    call remove(yrange, 0)
  endif
  for ny in yrange
    for nx in xrange
      let from = tiles[ny][nx]
      let to = tiles[ny + a:dy][nx + a:dx]
      let appended = self.append_tile(from, to)
      if appended
        let moved += [[nx, ny, from]]
        let tiles[ny + a:dy][nx + a:dx] = appended
        let tiles[ny][nx] = 0
      endif
    endfor
  endfor
  return {
  \   'tiles': tiles,
  \   'moved': moved,
  \ }
endfunction

function! s:Threes.next_tile_positions(dx, dy, moved)
  let moved = copy(a:moved)
  if a:dx
    let x = a:dx < 0 ? self.width() - 1 : 0
    let ys = s:List.uniq(map(moved, 'v:val[1]'))
    return map(ys, '[x, v:val]')
  endif
  if a:dy
    let y = a:dy < 0 ? self.height() - 1 : 0
    let xs = s:List.uniq(map(moved, 'v:val[0]'))
    return map(xs, '[v:val, y]')
  endif
  return []
endfunction

function! s:Threes.next(dx, dy)
  let result = self.move(a:dx, a:dy)
  if !empty(result.moved)
    let positions = self.next_tile_positions(a:dx, a:dy, result.moved)
    let [next_x, next_y] = s:sample(positions)
    try
      let next_tile = [next_x - a:dx, next_y - a:dy, self.next_tile()]
      call self.animate_slide(a:dx, a:dy, result.moved, next_tile)
    finally
      let self._state.tiles = result.tiles
      call self.set_tile(next_x, next_y, self.next_tile())
      let self._state.next_tile = self.random_tile()
      let self._state.tick += 1
    endtry
  endif
  return self
endfunction

function! s:Threes.animate_slide(dx, dy, moved, next_tile)
  let renderer = self._renderer
  let width = renderer._tile_width + strwidth(renderer._chars.vertical)
  let height = renderer._tile_height + 1
  call renderer.set_moved_tile(a:moved + [a:next_tile])

  let ticks = abs(min([width, height]))
  for n in range(ticks)
    let pos_x = a:dx * width * n / ticks
    let pos_y = a:dy * height * n / ticks
    call renderer.set_tile_animate(pos_x, pos_y)
    call self.render()
    sleep 10ms
  endfor

  call renderer.reset_tile_animate()
endfunction

function! s:Threes.random_tile()
  " large number
  let max_tile_radix = self.exp(self.highest_tile())
  let exp = max_tile_radix - self._setting.large_num_limit
  if 0 < exp && s:random(self._setting.large_num_odds) == 0
    let base = self.base_number()
    let candidates = map(range(1, exp), 'base * float2nr(pow(2, v:val))')
    return s:sample(candidates)
  endif

  " from deck
  if empty(self._state.deck)
    let self._state.deck = s:shuffle(copy(self._origin_deck))
  endif
  return remove(self._state.deck, 0)
endfunction

function! s:Threes.render()
  let content = self._renderer.render_game()

  setlocal modifiable noreadonly
  silent % delete _
  silent put =content
  silent 1 delete _
  setlocal nomodifiable readonly
  call cursor(1, 1)
  redraw
endfunction

function! s:Threes.exp(number)
  let base2 = a:number / self.base_number()
  return base2 == 0 ? -1 : float2nr(log(base2) / log(2))
endfunction

function! s:Threes.score(number)
  if a:number < self.base_number()
    return 0
  endif
  return float2nr(pow(self.base_number(), self.exp(a:number) + 1))
endfunction

function! s:Threes.total_score()
  return s:sum(map(self.tiles(), 'self.score(v:val)'))
endfunction

function! s:Threes.restart()
  if self.is_gameover() || s:confirm_quit_game('Restart')
    call self.start()
  endif
endfunction

function! s:Threes.quit()
  close
endfunction

function! s:Threes.tweet()
  if self.is_gameover()
    call s:tweet(self.total_score())
  endif
endfunction


let s:Renderer = {}

function! s:Renderer_new(...)
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
  let self._canvas = s:Canvas_new(self._canvas_width, 0)
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


" for test
function! threes#_canvas(...)
  return call('s:Canvas_new', a:000)
endfunction

" A simple canvas system.  This treats ascii character only.
let s:Canvas = {}

function! s:to_canvas(...)
  if type(a:1) == type({}) && has_key(a:1, '_field')
    return a:1
  endif
  return call('s:Canvas_new', a:000)
endfunction

function! s:Canvas_new(...)
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

function! threes#new(...)
  let threes = deepcopy(s:Threes)
  let setting = s:default_setting
  if a:0
    let setting = extend(copy(setting), a:1)
  endif
  call threes.init(setting)
  return threes
endfunction

function! threes#start()
  tabnew `='[threes]'`  " TODO: opener and bufname
  call s:define_keymappings()
  call s:init_buffer()
  if exists('s:current_threes') && !s:current_threes.is_gameover()
    let b:threes = s:current_threes
    call b:threes.render()
  else
    let b:threes = threes#new()
    let s:current_threes = b:threes
    call b:threes.start()
  endif
endfunction

function! s:init_buffer()
  setlocal readonly nomodifiable buftype=nofile bufhidden=wipe
  setlocal nonumber nowrap nolist
  setlocal nocursorline nocursorcolumn colorcolumn=
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
  \       :<C-u>call b:threes.restart()<CR>
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
  map <buffer> Q <Plug>(threes-quit)
  map <buffer> <C-l> <Plug>(threes-redraw)
  map <buffer> t <Plug>(threes-tweet)
endfunction

function! s:confirm_quit_game(action_mes)
  let msg = join([
  \   'Careful!',
  \   'You will lose all progress on your current board.',
  \   a:action_mes . ' this game?',
  \ ], "\n")
  let answer = confirm(msg, "&Yes\n&No", 2, 'Question')
  return answer == 1
endfunction

function! s:tweet(score)
  let score_str = substitute(a:score, '\v\d\zs\ze(\d{3})+$', ',', 'g')
  let tweet_text = printf(s:tweet_template, score_str)
  if get(g:, 'loaded_tweetvim', 0)
    call tweetvim#say#open(tweet_text)
    stopinsert
  elseif get(g:, 'loaded_openbrowser', 0)
    let url = 'https://twitter.com/intent/tweet?text=%s'
    call openbrowser#open(printf(url, tweet_text))
  endif
endfunction

" --- Utilities
function! s:sum(list)
  return eval(join(a:list, '+'))
endfunction

function! s:random(limit)
  let r = s:Random.rand()
  let n = r % a:limit
  return abs(n)
endfunction

function! s:shuffle(list)
  let pos = len(a:list)
  while 1 < pos
    let n = s:random(pos)
    let pos -= 1
    if n != pos
      let temp = a:list[n]
      let a:list[n] = a:list[pos]
      let a:list[pos] = temp
    endif
  endwhile
  return a:list
endfunction

function! s:sample(list)
  return a:list[s:random(len(a:list))]
endfunction

function! s:centerize(str, width, ...)
  let char = a:0 ? a:1 : ' '
  let w = strwidth(a:str)
  let padding = a:width - w
  let left = padding / 2
  let right = padding - left
  return repeat(char, left) . a:str . repeat(char, right)
endfunction

function! s:head(x, size)
  return a:size != 0           ? a:x[: a:size - 1] :
  \      type(a:x) == type('') ? '' : []
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


let &cpo = s:save_cpo
unlet s:save_cpo
