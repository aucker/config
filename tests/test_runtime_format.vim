" Source only the formatting code, never plugin bootstraps or the full vimrc.
execute 'set runtimepath^=' . fnameescape($DOTFILES_TEST_REPO . '/packages/vim/.vim')
execute 'edit ' . fnameescape($DOTFILES_TEST_FILE)
call setline(1, ['int main(){', 'return 0;', '}'])
call cursor(2, 3)
let $DOTFILES_FORMAT_MODE = 'expand'
call assert_equal(1, dotfiles#format())
call assert_equal(['int main() {', '  return 0;', '}'], getline(1, '$'))
call assert_equal([2, 3], getcurpos()[1:2])
call assert_equal(['--assume-filename=' . expand('%:p')], readfile($DOTFILES_FORMAT_ARGS))
call assert_equal(['int main(){', 'return 0;', '}'], readfile($DOTFILES_FORMAT_INPUT))

let $DOTFILES_FORMAT_MODE = 'shrink'
call assert_equal(1, dotfiles#format())
call assert_equal(['int main() {}'], getline(1, '$'))

let before = getline(1, '$')
let $DOTFILES_FORMAT_MODE = 'fail'
call assert_equal(0, dotfiles#format())
call assert_equal(before, getline(1, '$'))
let $DOTFILES_FORMAT_MODE = 'empty'
call assert_equal(0, dotfiles#format())
call assert_equal(before, getline(1, '$'))

let saved_path = $PATH
let $PATH = $DOTFILES_TEST_EMPTY_BIN
call assert_equal(0, dotfiles#format())
call assert_equal(before, getline(1, '$'))
let $PATH = saved_path

" All three vimrc variants must register one save callback, even when reloaded.
let $DOTFILES_FORMAT_MODE = 'expand'
for fragment in glob($DOTFILES_TEST_FORMAT_FRAGMENTS . '/*.vim', 0, 1)
  execute 'source ' . fnameescape(fragment)
  execute 'source ' . fnameescape(fragment)
  call delete($DOTFILES_FORMAT_CALLS)
  doautocmd dotfiles_clang_format BufWritePre
  call assert_equal(1, len(readfile($DOTFILES_FORMAT_CALLS)))
endfor

if !empty(v:errors)
  call writefile(v:errors, $DOTFILES_TEST_ERROR_LOG)
  cquit 1
endif
qa!
