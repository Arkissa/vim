vim9script

if exists(":Git") == 2
	:nnoremap <silent> gb <CMD>Git blame --date=short<CR>
	:nnoremap <silent> <Leader>g <CMD>:vertical Git<CR>
	:nnoremap <silent> <Leader>d <CMD>:Gvdiffsplit!<CR>
endif
