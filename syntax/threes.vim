" Syntax file for threes
" Version: 1.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:current_syntax')
  finish
endif

if !exists('b:threes')
  finish
endif

syntax match threesOriginTile1 /\.*\d*\.\+/ contains=threesOriginNumber1
syntax match threesOriginTile2 /,*\d*,\+/ contains=threesOriginNumber2
syntax match threesNormalTile /_*\d*_\+/ contains=threesNormalNumber
syntax match threesHighestTile /\**\d*\*\+/ contains=threesHighestNumber
syntax match threesOriginNumber1 /\d\+/ contained
syntax match threesOriginNumber2 /\d\+/ contained
syntax match threesNormalNumber /\d\+/ contained
syntax match threesHighestNumber /\d\+/ contained

syntax match threesNextArea /^\s*|\([.,_*]\)\1*+\?\1*|\s*$/ contains=threesNextBigTile,threesOriginTile1,threesOriginTile2,threesNormalTile
syntax match threesNextBigTile /_\++_\+/ contains=threesNextBigMark contained
syntax match threesNextBigMark /+/ contained

if has('gui_running') || &t_Co == 256
  highlight default threesOriginTile1   ctermbg=81  ctermfg=81  guibg=#66CCFF guifg=#66CCFF
  highlight default threesOriginTile2   ctermbg=204 ctermfg=204 guibg=#FF6680 guifg=#FF6680
  highlight default threesNormalTile    ctermbg=231 ctermfg=231 guibg=#FFFFFF guifg=#FFFFFF
  highlight default threesHighestTile   ctermbg=231 ctermfg=231 guibg=#FFFFFF guifg=#FFFFFF
  highlight default threesOriginNumber1 ctermbg=81  ctermfg=231 guibg=#66CCFF guifg=#FFFFFF
  highlight default threesOriginNumber2 ctermbg=204 ctermfg=231 guibg=#FF6680 guifg=#FFFFFF
  highlight default threesNormalNumber  ctermbg=231 ctermfg=16  guibg=#FFFFFF guifg=#000000
  highlight default threesHighestNumber ctermbg=231 ctermfg=204 guibg=#FFFFFF guifg=#FF6680
else
  highlight default threesOriginTile1   ctermfg=Blue  ctermbg=Blue  guifg=#66CCFF guibg=#66CCFF
  highlight default threesOriginTile2   ctermfg=Red   ctermbg=Red   guifg=#FF6680 guibg=#FF6680
  highlight default threesNormalTile    ctermfg=White ctermbg=White guifg=White   guibg=White
  highlight default threesHighestTile   ctermfg=White ctermbg=White guifg=White   guibg=White
  highlight default threesOriginNumber1 ctermfg=White ctermbg=Blue  guifg=White   guibg=#66CCFF
  highlight default threesOriginNumber2 ctermfg=White ctermbg=Red   guifg=White   guibg=#FF6680
  highlight default threesNormalNumber  ctermfg=Black ctermbg=White guifg=Black   guibg=White
  highlight default threesHighestNumber ctermfg=Red   ctermbg=White guifg=#FF6680 guibg=White
endif

highlight default link threesNextBigTile threesNormalTile
highlight default link threesNextBigMark threesNormalNumber


let b:current_syntax = 'threes'
