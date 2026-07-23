vim9script

import 'buffer.vim'
import 'window.vim'
import 'autocmd.vim'
import 'vim.vim'
import 'log.vim'
import 'timer.vim'
import 'thread.vim'

type Buffer = buffer.Buffer
type Window = window.Window
type Autocmd = autocmd.Autocmd

const ExcludeFiletype = ["xxd", "gitrebase", "tutor", "help", "gitcommint", "git", "fugitive", "fugitiveblame"]
const ExcludeBuftype = ["quickfix", "terminal", "help", "xxd"]

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
			setcursorcharpos(lnum, col)
		endif
	})
	.Desc('highlight tail whitespace on window.')
	.Once()
	.Callback(thread.Wrap(TailWhitespaceHighlight))

Autocmd.new('WinNew')
	.Desc('highlight tail whitespace on window.')
	.Group(g:myvimrc_group)
	.Callback(thread.Wrap(TailWhitespaceHighlight))

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
			if &buftype != '' || &readonly || !&modifiable || mode() =~# 'i'
				return
			endif

			thread.Fork(function('execute', ['checktime']))
		enddef

		au.Callback(timer.Timer.new(&updatecount, Checktime).Reset)
	})

def Available(): bool
	return executable('wl-copy') && executable('wl-paste')
enddef

def Copy(reg: string, type: string, str: list<string>)
	var args = "wl-copy"

	if reg == "*"
		args ..= " -p"
	endif

	system(args, str)
	# clean dirty control code return from wl-copy.
	:redraw!
enddef

def Paste(reg: string): tuple<string, list<string>>
	var args = ["wl-paste", "--type", "text/plain;charset=utf-8", "--no-newline"]

	if reg == "*"
		args->add("-p")
	endif

	return ("", systemlist(args))
enddef

v:clipproviders["wl_clipboard"] = {
	available: Available,
	copy: {
		"+": Copy,
		"*": Copy
	},
	paste: {
		"+": Paste,
		"*": Paste
	}
}

Autocmd.new('VimEnter')
	.Group(g:myvimrc_group)
	.Desc('statusline')
	.Command('set statusline=%!statusline#Statusline()')
	.Once()
	.Desc('set autoread')
	.Callback(thread.Wrap(function('execute', ['set autoread'])))
	.Desc('see https://github.com/vim/vim/blob/master/runtime/doc/wayland.txt#L56-L103')
	.Callback(() => {
		if has('wayland_clipboard')
			&& !has('gui_running')
			&& !empty(v:wayland_display)
			&& v:clipmethod ==# 'none'

			&clipmethod = 'wl_clipboard'
		endif
	})
	.Desc('gvim load session will redraw screen.')
	.Callback(thread.Wrap(() => {
		if has('gui_running')
			:redraw!
		endif
	}))

Autocmd.new('TerminalOpen')
	.Desc('set signcolumn=no and nowrap for terminal.')
	.Group(g:myvimrc_group)
	.Callback((attr) => {
		var b = buffer.Buffer.newByBufnr(attr.buf)
		b.SetVar('&signcolumn', 'no')
		b.SetVar('&wrap', false)
		b.SetVar('&number', false)
	})

Autocmd.new('CompleteChanged')
	.Group(g:myvimrc_group)
	.Callback(() => {
		var popid = popup_findinfo()
		var options = popup_getoptions(popid)
		if has_key(options, 'filter')
			return
		endif

		popup_setoptions(popid, {
			filter: (winid, key) => {
				var win = Window.newByWinnr(winid)
				if vim.Contains(["\<C-u>", "\<C-d>"], key)
					win.ExecuteCallback(() => {
						execute($"normal! {key}")
					})
					return true
				endif
				return false
			}})
	})

Autocmd.new('StdinReadPost')
	.Group(g:myvimrc_group)
	.Command('if &modified | &modified = false | endif')

Autocmd.new('FileType')
	.Group(g:myvimrc_group)
	.Pattern(['qf'])
	.Command(':packadd cfilter')
