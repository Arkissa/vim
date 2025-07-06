vim9script

:nmap <silent> [l <CMD>lprevious<CR>
:nmap <silent> ]l <CMD>lnext<CR>
:nmap <silent> [q <CMD>cprevious<CR>
:nmap <silent> ]q <CMD>cnext<CR>

:vmap <silent> <nowait> <C-c> "+y

:imap <silent> <nowait> <C-v> <C-R>+
:imap <silent> <nowait> <C-A> <HOME>
:inoremap <C-F>  <Right>
:inoremap <C-B>  <Left>
:inoremap <A-b> <C-Left>
:inoremap <A-f> <C-Right>

:cnoremap <C-F>  <Right>
:cnoremap <C-B>  <Left>
:cnoremap <A-b> <C-Left>
:cnoremap <A-f> <C-Right>
:cnoremap <C-k> <CMD>vim9 (() => setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1)))()<CR>
:cnoremap <silent> <nowait> <C-A> <HOME>

:tnoremap <ESC> <C-\><C-n>

:nnoremap <silent> \\ @@
:nmap <nowait> gp <CMD>put "<CR>
:nmap <nowait> gP <CMD>-1put "<CR>
:nmap <nowait> [P i 
:nmap <nowait> ]P a 
:nmap <C-l> <CMD>nohlsearch<CR>
