" Syntax file for threes
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:current_syntax')
  finish
endif

if !exists('b:threes')
  finish
endif

syntax match threesOriginTile1 /\.\+\d*\.\+/ contains=threesOriginNumber1
syntax match threesOriginTile2 /,\+\d*,\+/ contains=threesOriginNumber2
syntax match threesOriginNumber1 /\d\+/ contained
syntax match threesOriginNumber2 /\d\+/ contained
syntax match threesHighestTile /\*\d\+\*/ contains=threesHighestNumber
syntax match threesHighestNumber /\d\+/ contained

highlight default threesOriginTile1   ctermfg=Blue  ctermbg=Blue guifg=#66CCFF guibg=#66CCFF
highlight default threesOriginTile2   ctermfg=Red   ctermbg=Red  guifg=#FF6680 guibg=#FF6680
highlight default threesOriginNumber1 ctermfg=White ctermbg=Blue guifg=White   guibg=#66CCFF
highlight default threesOriginNumber2 ctermfg=White ctermbg=Red  guifg=White   guibg=#FF6680
highlight default threesHighestTile   ctermfg=bg    ctermbg=bg   guifg=bg      guibg=bg
highlight default threesHighestNumber ctermfg=Red   ctermbg=bg   guifg=#FF6680 guibg=bg


let b:current_syntax = 'threes'
