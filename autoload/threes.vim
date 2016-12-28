" Play Threes! in Vim!
" Version: 1.6
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let g:threes#vital = vital#threes#new()
let s:Random = g:threes#vital.import('Random')
let s:List = g:threes#vital.import('Data.List')

if !exists('g:threes#data_directory')
  let g:threes#data_directory = expand('~/.threesvim')
endif

if !exists('g:threes#start_with_higher_tile')
  let g:threes#start_with_higher_tile = 0
endif

let s:tweet_template = 'I just scored %s (the highest number was %s) in threes.vim! https://github.com/thinca/vim-threes #threesvim'

let s:default_config = {
\   'width': 4,
\   'height': 4,
\   'origin_numbers': [1, 2],
\   'init_count': 9,
\   'init_higher_tile': 0,
\   'large_num_limit': 3,
\   'large_num_odds': 21,
\   'hide_large_next_tile': 0,
\   'large_next_tile_count': 3,
\ }

let s:step_patterns = [[-1, 0], [1, 0], [0, -1], [0, 1]]

let s:Threes = {}

function! s:Threes.init(config) abort
  let self._config = deepcopy(a:config)
  call self.update_config()
  let self._renderer = threes#renderer#new(self)
endfunction

function! s:Threes.update_config() abort
  let self._base_number = s:sum(self._config.origin_numbers)
  let origin_num = (self.width() + self.height()) / 2
  let self._origin_deck =
  \        repeat(self._config.origin_numbers, origin_num) +
  \        repeat([self.base_number()], origin_num)
endfunction

function! s:Threes.reset() abort
  let self._state = {}
  let self._state.tiles =
  \        map(range(self.width()), 'repeat([0], self.height())')
  let self._state.deck = []
  let self._state.steps = []

  let self._state.seed = get(self._config, 'seed', s:Random.next(1))
  let self._random = s:Random.new('', self._state.seed)
endfunction

function! s:Threes.width() abort
  return self._config.width
endfunction

function! s:Threes.height() abort
  return self._config.height
endfunction

function! s:Threes.base_number() abort
  return self._base_number
endfunction

function! s:Threes.get_tile(x, y) abort
  return self._state.tiles[a:y][a:x]
endfunction

function! s:Threes.set_tile(x, y, tile) abort
  let self._state.tiles[a:y][a:x] = a:tile
endfunction

function! s:Threes.tiles() abort
  return s:List.flatten(self._state.tiles)
endfunction

function! s:Threes.seed() abort
  return self._state.seed
endfunction

function! s:Threes.steps() abort
  return self._state.steps
endfunction

function! s:Threes.tile_list(...) abort
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

function! s:Threes.steps() abort
  return self._state.steps
endfunction

function! s:Threes.next_tile() abort
  return self._state.next_tile
endfunction

function! s:Threes.next_tile_candidates() abort
  return self._state.next_tile_candidates
endfunction

function! s:Threes.highest_tile() abort
  return max(self.tiles())
endfunction

function! s:Threes.is_origin(tile) abort
  return s:List.has(self._config.origin_numbers, a:tile)
endfunction

function! s:Threes.append_tile(from, to) abort
  if a:to == 0 ||
  \   (a:to == a:from ? self.base_number() <= a:to
  \                   : self.is_origin(a:to) && self.is_origin(a:from))
    return a:to + a:from
  endif
  return 0
endfunction

function! s:Threes.is_gameover() abort
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

function! s:Threes.new_game() abort
  call self.reset()

  let tile_count = self.width() * self.height()
  let tiles = range(tile_count)
  let init_count = self._config.init_count

  if self._config.init_higher_tile
    " put the higher tile on corner
    let x = self._random.sample([0, self.width() - 1])
    let y = self._random.sample([0, self.height() - 1])
    call self.set_tile(x, y, self._config.init_higher_tile)
    let pos = x + y * self.height()
    call filter(tiles, 'v:val != pos')
    let init_count -= 1
  endif

  let random_tiles = self._random.shuffle(tiles)
  let init_tiles = random_tiles[: init_count - 1]
  for pos in init_tiles
    let x = pos % self.width()
    let y = pos / self.height()
    call self.set_tile(x, y, self.random_tile(1))
  endfor
  call self.update_next_tile()
endfunction

function! s:Threes.start() abort
  call self.new_game()
  call self.render()
endfunction

function! s:Threes.move(dx, dy) abort
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

function! s:Threes.next_tile_positions(dx, dy, moved) abort
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

function! s:Threes.next(dx, dy) abort
  let result = self.move(a:dx, a:dy)
  if !empty(result.moved)
    let positions = self.next_tile_positions(a:dx, a:dy, result.moved)
    let [next_x, next_y] = self._random.sample(positions)
    try
      let next_tile = [next_x - a:dx, next_y - a:dy, self.next_tile()]
      call self.animate_slide(a:dx, a:dy, result.moved, next_tile)
    finally
      let self._state.tiles = result.tiles
      call self.set_tile(next_x, next_y, self.next_tile())
      call self.update_next_tile()
      let self._state.steps += [index(s:step_patterns, [a:dx, a:dy])]
    endtry
    if self.is_gameover()
      call threes#record#add(self)
      call s:save_record()
    endif
  endif
  return self
endfunction

function! s:Threes.update_next_tile() abort
  let self._state.next_tile = self.random_tile()
  let self._state.next_tile_candidates =
  \     self.make_next_tile_candidates(self._state.next_tile)
endfunction

function! s:Threes.make_next_tile_candidates(next_tile) abort
  let tile_count = self._config.large_next_tile_count
  if self._config.hide_large_next_tile ||
  \   tile_count <= 1 ||
  \   !self.is_large_number(a:next_tile)
    return [a:next_tile]
  endif

  let large_nums = self.large_numbers()
  if len(large_nums) <= tile_count
    return large_nums
  endif

  let index = index(large_nums, a:next_tile)
  let n = self._random.range(tile_count)
  let begin = index - n
  let begin = sort([0, begin, len(large_nums) - tile_count])[1]
  return large_nums[begin : begin + tile_count - 1]
endfunction

function! s:Threes.animate_slide(dx, dy, moved, next_tile) abort
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

function! s:Threes.random_tile(...) abort
  let not_use_large_number = a:0 ? a:1 : 0

  if !not_use_large_number
    " large number
    let large_nums = self.large_numbers()
    if len(large_nums) != 0 &&
    \   self._random.range(self._config.large_num_odds) == 0
      return self._random.sample(large_nums)
    endif
  endif

  " from deck
  if empty(self._state.deck)
    let self._state.deck = self._random.shuffle(copy(self._origin_deck))
  endif
  return remove(self._state.deck, 0)
endfunction

function! s:Threes.is_large_number(number) abort
  return self.base_number() < a:number
endfunction

function! s:Threes.large_numbers() abort
  let max_tile_radix = self.exp(self.highest_tile())
  let exp = max([max_tile_radix - self._config.large_num_limit, 0])
  let base = self.base_number()
  return map(range(1, exp), 'base * float2nr(pow(2, v:val))')
endfunction

function! s:Threes.render() abort
  let content = self._renderer.render_game()

  setlocal modifiable noreadonly
  silent % delete _
  silent put =content
  silent 1 delete _
  setlocal nomodifiable readonly
  call cursor(1, 1)
  redraw
endfunction

function! s:Threes.exp(number) abort
  let base2 = a:number / self.base_number()
  return base2 == 0 ? -1 : float2nr(log(base2) / log(2))
endfunction

function! s:Threes.score(number) abort
  if a:number < self.base_number()
    return 0
  endif
  return float2nr(pow(self.base_number(), self.exp(a:number) + 1))
endfunction

function! s:Threes.total_score() abort
  return s:sum(map(self.tiles(), 'self.score(v:val)'))
endfunction

function! s:Threes.restart(...) abort
  if self.is_gameover() || s:confirm_quit_game('Restart')
    if a:0
      call extend(self._config, a:1)
      call self.update_config()
    endif
    call self.start()
  endif
endfunction

function! s:Threes.quit() abort
  close
endfunction

function! s:Threes.tweet() abort
  if self.is_gameover()
    call s:tweet(self.total_score(), self.highest_tile())
  endif
endfunction


function! threes#new(...) abort
  let threes = deepcopy(s:Threes)
  let config = s:default_config
  if a:0
    let config = extend(copy(config), a:1)
  endif
  call threes.init(config)
  return threes
endfunction

function! threes#start() abort
  tabnew `='threes://play'`  " TODO: opener
endfunction

function! threes#show_record() abort
  tabnew `='threes://record'`  " TODO: opener
endfunction

function! s:confirm_quit_game(action_mes) abort
  let msg = join([
  \   'Careful!',
  \   'You will lose all progress on your current board.',
  \   a:action_mes . ' this game?',
  \ ], "\n")
  let answer = confirm(msg, "&Yes\n&No", 2, 'Question')
  return answer == 1
endfunction

function! s:tweet(score, highest_num) abort
  let score_str = substitute(a:score, '\v\d\zs\ze(\d{3})+$', ',', 'g')
  let tweet_text = printf(s:tweet_template, score_str, a:highest_num)
  if get(g:, 'loaded_tweetvim', 0)
    call tweetvim#say#open(tweet_text)
    stopinsert
  elseif get(g:, 'loaded_openbrowser', 0)
    let url = 'https://twitter.com/intent/tweet?text=%s'
    call openbrowser#open(printf(url, tweet_text))
  endif
endfunction

function! s:save_record() abort
  if empty(g:threes#data_directory)
    return
  endif
  if !isdirectory(g:threes#data_directory)
    call mkdir(g:threes#data_directory, 'p')
  endif
  call threes#record#save(g:threes#data_directory . '/records.dat')
endfunction

call threes#record#load(g:threes#data_directory . '/records.dat')

" --- Utilities
function! s:sum(list) abort
  return eval(join(a:list, '+'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
