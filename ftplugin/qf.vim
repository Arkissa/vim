import autoload "quickfix.vim"

:setlocal nolist
:setlocal nowrap
:setlocal nobuflisted
:setlocal norelativenumber

:nnoremap <buffer> <silent> u <CMD>colder<CR>
:nnoremap <buffer> <silent> <C-r> <CMD>cnewer<CR>
:nnoremap <buffer> K <CMD>call quickfix#Previewer.Toggle()<CR>
