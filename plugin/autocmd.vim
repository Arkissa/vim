vim9script

import 'buffer.vim'
import 'autocmd.vim'
import 'statusline.vim'

type Autocmd = autocmd.Autocmd
type Buffer = buffer.Buffer

const ExcludeFiletype = ["xxd", "gitrebase", "tutor", "help", "commint"]
const ExcludeBuftype = ["quickfix", "terminal", "help", "xxd"]
const group = 'MYVIMRC'

g:statusline = statusline.helper

Autocmd.new('BufReadPost')
	.Group(group)
	.Callback(() => {
		var [lnum, col] = Buffer.newCurrent().LastCursorPosition()
		if index(ExcludeFiletype, &filetype) == -1
			cursor(lnum, col)
		endif
	})
	.Callback(() => {
		if index(ExcludeFiletype, &filetype) == -1
		|| index(ExcludeBuftype, &buftype) == -1
			matchadd('Search', '\s\+$')
		endif
	})

Autocmd.new('BufEnter')
	.Group(group)
	.Callback(() => {
		var wininfos = getwininfo()
		for wininfo in wininfos
			if getbufvar(wininfo.bufnr, "&buftype") ==# ""
				return
			endif
		endfor

		execute('quitall!')
	})

Autocmd.new('InsertLeave')
	.Group(group)
	.When(() => executable('ibus') == 1)
	.Command('system("ibus engine xkb:us::eng")')

Autocmd.new('CmdlineChanged')
	.Group(group)
	.Pattern(['[:/\?]'])
	.Callback(function('wildtrigger', []))

Autocmd.newMulti(['WinEnter', 'BufEnter'])
	.Group(group)
	.Command('setlocal cursorline')

Autocmd.newMulti(['WinLeave', 'BufLeave'])
	.Group(group)
	.Command('setlocal nocursorline')

Autocmd.new('VimEnter')
	.Group(group)
	.Command('set statusline=%{%g:statusline.Cut().Mode().BufName().Diags().Right().Git().FileType().Dir().Role().Build()%}')
