vim9script

import 'buffer.vim'
import 'autocmd.vim'
import 'statusline.vim'

type Autocmd = autocmd.Autocmd
type Buffer = buffer.Buffer

const ExcludeFiletype = ["xxd", "gitrebase", "tutor", "help", "commint"]
const ExcludeBuftype = ["quickfix", "terminal", "help", "xxd"]

g:statusline = statusline.helper

Autocmd.new('BufReadPost')
	.Group(g:myvimrc_group)
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
	.Group(g:myvimrc_group)
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
	.Group(g:myvimrc_group)
	.When(() => executable('ibus') == 1)
	.Command('system("ibus engine xkb:us::eng")')

Autocmd.new('CmdlineChanged')
	.Group(g:myvimrc_group)
	.Pattern(['[:/\?]'])
	.Callback(function('wildtrigger', []))

Autocmd.newMulti(['WinEnter', 'BufEnter'])
	.Group(g:myvimrc_group)
	.Command('setlocal cursorline')

Autocmd.newMulti(['WinLeave', 'BufLeave'])
	.Group(g:myvimrc_group)
	.Command('setlocal nocursorline')

Autocmd.new('VimEnter')
	.Group(g:myvimrc_group)
	.Command('set statusline=%{%g:statusline.Cut().Mode().BufName().Diags().Right().Git().FileType().Dir().Role().Build()%}')

Autocmd.new('OptionSet')
	.Group(g:myvimrc_group)
	.Pattern(['autoread'])
	.Callback(() => {
		const group = 'real-autoread'
		const is_local = v:option_type == 'local'

		var opts: dict<any> = {
			group: group}

		if is_local
			opts.bufnr = bufnr()
		endif

		if !v:option_new->str2nr()
			autocmd_delete([opts])
			return
		endif

		var au = Autocmd.newMulti([
			'FocusGained',
			'BufEnter',
			'CursorHold',
			'CursorHoldI',
		]).Group(group)

		if is_local
			au.Bufnr(bufnr())
		endif

		au.Command('checktime')
	})
