" The manual command is restricted to clang-format's C/C++ use here.
function! dotfiles#format_manual() abort
  if index(['c', 'cpp'], &l:filetype) < 0
    echomsg 'Format supports C/C++ buffers only'
    return 0
  endif
  if !executable('clang-format')
    echomsg 'Install clang-format on PATH to format C/C++ buffers'
    return 0
  endif
  return dotfiles#format()
endfunction

" Format the current buffer through PATH, without a Python provider or -i writes.
function! dotfiles#format() abort
  if !&l:modifiable || &l:binary || &l:buftype !=# '' || !executable('clang-format')
    return 0
  endif
  let l:filename = expand('%:p')
  if empty(l:filename)
    let l:filename = 'buffer.cpp'
  endif
  " Resolve before invoking the user's shell, which may alter PATH on startup.
  let l:command = shellescape(exepath('clang-format')) . ' --assume-filename=' . shellescape(l:filename)
  let l:input = join(getline(1, '$'), "\n") . "\n"
  let l:output = system(l:command, l:input)
  if v:shell_error != 0 || empty(l:output)
    echohl WarningMsg
    echomsg 'clang-format failed; buffer left unchanged'
    echohl None
    return 0
  endif

  let l:lines = split(l:output, "\n", 1)
  if !empty(l:lines) && l:lines[-1] ==# ''
    call remove(l:lines, -1)
  endif
  if empty(l:lines)
    return 0
  endif
  let l:view = winsaveview()
  try
    if l:lines !=# getline(1, '$')
      call setline(1, l:lines)
      if line('$') > len(l:lines)
        silent! undojoin
        execute 'silent keepjumps ' . (len(l:lines) + 1) . ',$delete _'
      endif
    endif
  finally
    call winrestview(l:view)
  endtry
  return 1
endfunction
