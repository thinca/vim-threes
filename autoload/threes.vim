" Play Threes! in Vim!
" Version: 1.2
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
  let self._setting.base_number = s:sum(self._setting.origin_numbers)
  let self._tiles = map(range(self.width()), 'repeat([0], self.height())')

  let origin_num = (self.width() + self.height()) / 2
  let self._origin_deck = repeat(self._setting.origin_numbers, origin_num) +
  \                       repeat([self.base_number()], origin_num)
  let self._deck = []
endfunction

function! s:Threes.width()
  return self._setting.width
endfunction

function! s:Threes.height()
  return self._setting.height
endfunction

function! s:Threes.base_number()
  return self._setting.base_number
endfunction

function! s:Threes.get_tile(x, y)
  return self._tiles[a:y][a:x]
endfunction

function! s:Threes.set_tile(x, y, tile)
  let self._tiles[a:y][a:x] = a:tile
endfunction

function! s:Threes.tiles()
  return s:List.flatten(self._tiles)
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

function! s:Threes.next_tile_str()
  let next = self._next_tile
  return self.base_number() < next ? '+' : string(next)
endfunction

function! s:Threes.tile_color_char(tile)
  let colors = ['_', ' ', '.', ',']
  return colors[index([0] + self._setting.origin_numbers, a:tile) + 1]
endfunction

function! s:Threes.new_game()
  let tile_count = self.width() * self.height()
  let init_tiles = s:shuffle(range(tile_count))[: self._setting.init_count - 1]
  for pos in init_tiles
    let x = pos % self.width()
    let y = pos / self.height()
    call self.set_tile(x, y, self.random_tile())
  endfor
  let self._next_tile = self.random_tile()
endfunction

function! s:Threes.start()
  call self.new_game()
  call self.render()
endfunction

function! s:Threes.move(dx, dy)
  let tiles = deepcopy(self._tiles)
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
        let moved += [[nx, ny]]
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
    let self._tiles = result.tiles
    let positions = self.next_tile_positions(a:dx, a:dy, result.moved)
    let [next_x, next_y] = s:sample(positions)
    call self.set_tile(next_x, next_y, self._next_tile)

    if self.is_gameover()
    else
      let self._next_tile = self.random_tile()
    endif
  endif
  return self
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
  if empty(self._deck)
    let self._deck = s:shuffle(copy(self._origin_deck))
  endif
  return remove(self._deck, 0)
endfunction

function! s:Threes.render()
  let tile_width = 6
  let tile_height = 3
  let horizontal = '-'
  let vertical = '|'
  let cross = '+'

  let tile_horizontal_line = cross . repeat(horizontal, tile_width)
  let horizontal_line = repeat(tile_horizontal_line, self.width()) . cross
  let board_width = strwidth(horizontal_line)

  let content = []

  " Render gameover message
  let gameover = self.is_gameover()
  if gameover
    let content += [s:centerize('Out of moves!', board_width), '']
  else
    let content += ['', '']
  endif

  " Render next
  let color = self.tile_color_char(self._next_tile)
  let content += [s:centerize('NEXT', board_width)]
  let content += [s:centerize(tile_horizontal_line . cross, board_width)]
  let next_tile = s:centerize(self.next_tile_str(), tile_width, color)
  let content += [s:centerize(vertical . next_tile . vertical, board_width)]
  let content += [s:centerize(tile_horizontal_line . cross, board_width)]

  let top_blank = (tile_height - 1) / 2
  let bottom_blank = tile_height - 1 - top_blank

  " Render board
  let highest = self.highest_tile()
  if highest == self.base_number()
    let highest = -1
  endif

  for line in self._tiles
    let content += [horizontal_line]
    let line_tiles = repeat([vertical], tile_height)
    for tile in line
      let color = self.tile_color_char(tile)
      for n in range(tile_height)
        if n == tile_height / 2
          let tile_str = tile == 0 ? ''
          \            : tile == highest ? '*' . tile . '*'
          \            : tile
          let line_tiles[n] .= s:centerize(tile_str, tile_width, color)
        else
          let line_tiles[n] .= repeat(color, tile_width)
        endif
        let line_tiles[n] .= vertical
      endfor
    endfor
    let content += line_tiles
  endfor
  let content += [horizontal_line]

  " Render score
  if gameover
    let content += ['', s:centerize('score: ' . self.total_score(), board_width)]
  endif

  call map(content, 'substitute(v:val, "\\s\\+$", "", "")')

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

function! s:Threes.tweet()
  if self.is_gameover()
    call s:tweet(self.total_score())
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
  let b:threes = threes#new()
  call s:define_keymappings()
  call s:init_buffer()
  call b:threes.start()
endfunction

function! s:init_buffer()
  setlocal readonly nomodifiable buftype=nofile
  setlocal nonumber nowrap nolist
  setlocal nocursorline nocursorcolumn colorcolumn=
  setlocal filetype=threes
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
  noremap <buffer> <silent> <Plug>(threes-redraw)
  \       :<C-u>call b:threes.render()<CR>
  noremap <buffer> <silent> <Plug>(threes-tweet)
  \       :<C-u>call b:threes.tweet()<CR>

  map <buffer> h <Plug>(threes-move-left)
  map <buffer> j <Plug>(threes-move-down)
  map <buffer> k <Plug>(threes-move-up)
  map <buffer> l <Plug>(threes-move-right)
  map <buffer> <C-l> <Plug>(threes-redraw)
  map <buffer> t <Plug>(threes-tweet)
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


let &cpo = s:save_cpo
unlet s:save_cpo
