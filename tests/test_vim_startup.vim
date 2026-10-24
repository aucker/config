" Run with an isolated home and the complete vimrc, including built-in plugins.
let start_dir = getcwd()
execute 'edit ' . fnameescape($DOTFILES_TEST_FILE)
call assert_equal(start_dir, getcwd())
call assert_equal(0, exists(':PlugInstall'))
call assert_equal(0, exists(':Autoformat'))
call assert_equal(2, exists(':Format'))
call assert_equal(2, exists(':Explore'))
call assert_notmatch('/plugged/', execute('scriptnames'))

" Browsing and returning to the file should work without NERDTree.
let g:netrw_dirhistmax = 0
Explore
call assert_equal('netrw', &l:filetype)
execute 'edit ' . fnameescape($DOTFILES_TEST_FILE)
call assert_equal(['fixture'], getline(1, '$'))

if !empty(v:errors)
  call writefile(v:errors, $DOTFILES_TEST_ERROR_LOG)
  cquit 1
endif
qa!
