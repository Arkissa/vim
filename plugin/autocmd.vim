vim9script

import 'buffer.vim'
import 'window.vim'
import 'autocmd.vim'
import 'statusline.vim'
import 'vim.vim'
import 'timer.vim'

type Buffer = buffer.Buffer
type Window = window.Window
type Autocmd = autocmd.Autocmd

const ExcludeFiletype = ["xxd", "gitrebase", "tutor", "help", "gitcommint", "git", "fugitive", "fugitiveblame"]
const ExcludeBuftype = ["quickfix", "terminal", "help", "xxd"]

g:statusline = statusline.helper

def TailWhitespaceHighlight()
	var win = Window.newCurrent()
	var buf = win.GetBuffer()

	if vim.Contains(ExcludeFiletype, buf.GetVar('&filetype')) || vim.Contains(ExcludeBuftype, buf.GetVar('&buftype'))
		return
	endif

	var matchid = matchadd('Search', '\s\+$', 10, -1, {
		window: win.winnr,
	})

	Autocmd.new('WinClosed')
		.Group(g:myvimrc_group)
		.Once()
		.Desc($'window with ID {win.winnr} is hilighted with remove tail whitespace.')
		.Pattern([win.winnr->string()])
		.Command($'matchdelete({matchid}, {win.winnr})')
enddef

Autocmd.new('BufReadPost')
	.Group(g:myvimrc_group)
	.Desc('auto jump to last cursor position if a buffer read post.')
	.Callback(() => {
		var [lnum, col] = Buffer.newCurrent().LastCursorPosition()
		if !vim.Contains(ExcludeFiletype, &filetype)
			cursor(lnum, col)
		endif
	})
	.Desc('highlight tail whitespace on window.')
	.Once()
	.Callback(() => {
		vim.NapCall(TailWhitespaceHighlight)
	})


Autocmd.new('WinNew')
	.Desc('highlight tail whitespace on window.')
	.Group(g:myvimrc_group)
	.Callback(() => {
		vim.NapCall(TailWhitespaceHighlight)
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

Autocmd.new('OptionSet')
	.Group(g:myvimrc_group)
	.Pattern(['autoread'])
	.Callback(() => {
		const real_autoread_group = 'RealAutoRead'
		const is_local = v:option_type == 'local'

		var opts: dict<any> = {
			group: real_autoread_group}

		if is_local
			opts.bufnr = bufnr()
		endif

		if !v:option_new->str2nr()
			Autocmd.Delete([opts])
			return
		endif

		var au = Autocmd.newMulti([
			'FocusGained',
			'BufEnter',
			'CursorHold',
		]).Group(real_autoread_group)

		if is_local
			au.Bufnr(bufnr())
		endif

		def Checktime(_: timer.Timer)
			if &buftype != '' || &readonly || !&modifiable
				return
			endif

			execute('checktime')
		enddef

		au.Callback(timer.Timer.new(&updatecount, Checktime).Reset)
	})

def ExcludeSpecialLockWindowSize()
	const group = 'ExcludeSpecialLockWindowSize'
	var saved: list<dict<any>>

	Autocmd.new('CmdWinEnter')
		.Group(group)
		.Callback(() => {
			saved = Autocmd.Get({group: 'LockWindowSize'})
			if saved->empty()
				return
			endif

			Autocmd.Delete([{group: 'LockWindowSize'}], false)
			execute($'resize {&cmdwinheight}')
		})

	Autocmd.new('CmdWinLeave')
		.Group(group)
		.Callback(() => {
			autocmd_add(saved)
		})
enddef

Autocmd.new('VimEnter')
	.Group(g:myvimrc_group)
	.Command('set statusline=%{%g:statusline.Cut().Mode().BufName().Diags().Right().Git().FileType().Dir().Role().Build()%}')
	.Once()
	.Callback(ExcludeSpecialLockWindowSize)
	.Callback(() => {
		vim.NapCall(function('execute', ['set autoread']))
	})
