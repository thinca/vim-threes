let s:UI = themis#suite('UI')
call themis#helper('command').with(themis#helper('assert'))

function! s:UI.command() abort
  Assert Equals(exists(':ThreesStart'), 2)
endfunction
