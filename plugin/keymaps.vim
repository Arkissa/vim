vim9script

:nmap <silent> [l <CMD>lprevious<CR>
:nmap <silent> ]l <CMD>lnext<CR>
:nmap <silent> [q <CMD>cprevious<CR>
:nmap <silent> ]q <CMD>cnext<CR>

:vmap <silent> <nowait> <C-c> "+y

:imap <silent> <nowait> <C-v> <C-R>+
:imap <silent> <nowait> <C-A> <HOME>
:inoremap <C-f>  <Right>
:inoremap <C-b>  <Left>
:inoremap <M-b> <C-Left>
:inoremap <M-f> <C-Right>

:cnoremap <C-f> <Right>
:cnoremap <C-b> <Left>
:cnoremap <M-b> <C-Left>
:cnoremap <M-f> <C-Right>
:cnoremap <C-k> <CMD>vim9 (() => setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1)))()<CR>
:cnoremap <silent> <nowait> <C-A> <HOME>

:tnoremap <ESC> <C-\><C-n>

:nnoremap <silent> \\ @@
:nmap <nowait> gp <CMD>put "<CR>
:nmap <nowait> gP <CMD>-1put "<CR>
:nmap <nowait> [P i 
:nmap <nowait> ]P a 
:nmap <C-l> <CMD>nohlsearch<CR>
