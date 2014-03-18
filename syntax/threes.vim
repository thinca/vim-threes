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
syntax match threesNormalTile /_\+\(*\?\)\d*\1_\+/ contains=threesNormalNumber,threesHighestTile
syntax match threesOriginNumber1 /\d\+/ contained
syntax match threesOriginNumber2 /\d\+/ contained
syntax match threesNormalNumber /\d\+/ contained

syntax match threesHighestTile /\*\d\+\*/ contains=threesHighestNumber,threesHighestMark
syntax match threesHighestNumber /\d\+/ contained
syntax match threesHighestMark /\*/ contained

highlight default threesOriginTile1   ctermfg=Blue  ctermbg=Blue  guifg=#66CCFF guibg=#66CCFF
highlight default threesOriginTile2   ctermfg=Red   ctermbg=Red   guifg=#FF6680 guibg=#FF6680
highlight default threesNormalTile    ctermfg=White ctermbg=White guifg=White   guibg=White
highlight default threesOriginNumber1 ctermfg=White ctermbg=Blue  guifg=White   guibg=#66CCFF
highlight default threesOriginNumber2 ctermfg=White ctermbg=Red   guifg=White   guibg=#FF6680
highlight default threesNormalNumber  ctermfg=Black ctermbg=White guifg=Black   guibg=White

highlight default threesHighestMark   ctermfg=White ctermbg=White guifg=White   guibg=White
highlight default threesHighestNumber ctermfg=Red   ctermbg=White guifg=#FF6680 guibg=White


let b:current_syntax = 'threes'
