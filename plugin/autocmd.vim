vim9script

var exclude_filetype = ["xxd", "gitrebase", "tutor", "help", "commint"]
var exclude_buftype = ["quickfix", "terminal"]

def JumpBack()
    var lnum = line("'\"")
    if lnum >= 1
	&& lnum <= line("$")
	&& index(exclude_filetype, &filetype) == -1
		:execute "normal! g`\""
    endif
enddef

def HighlightTailSpace()
    if index(exclude_filetype, &filetype) == -1
	|| index(exclude_buftype, &buftype) == -1
		match Search /\s\+$/
    endif
enddef

def SmartQuitall()
    var wininfos = getwininfo()
    for wininfo in wininfos
		if getbufvar(wininfo.bufnr, "&buftype") ==# ""
			return
		endif
    endfor

    :quitall
enddef

var last_mode = ""
augroup MYVIMRC
    autocmd BufReadPost * vim9 JumpBack() | HighlightTailSpace()
    autocmd BufEnter * vim9 SmartQuitall()
    autocmd WinEnter,BufEnter * setlocal cursorline
    autocmd WinLeave,BufLeave * setlocal nocursorline

    if executable("ibus")
		autocmd InsertLeave * {
			last_mode = system("ibus engine")->trim()
			if last_mode !=# "xkb:us::eng"
				system("ibus engine xkb:us::eng")
			endif
		}

		autocmd InsertEnter * {
			if last_mode !=# ""
				system("ibus engine " .. last_mode)
			endif
		}
    endif
augroup END
