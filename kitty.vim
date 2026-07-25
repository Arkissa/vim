vim9script

if !has('terminal')
  echoerr 'kitty scrollback requires Vim +terminal'
  finish
endif

if $TERM != 'xterm-kitty'
	echoerr '$TERM must be kitty'
	finish
endif

const SetEditorVar = $"\e]1337;SetUserVar=in_editor={base64_encode(str2blob(['1']))}\e\\"
const UnsetEditorVar = "\e]1337;SetUserVar=in_editor\e\\"

def SendKittyOSC(seq: string)
	try
		writefile([seq], '/dev/tty', 'b')
	catch
	endtry
enddef

augroup KittyScroolback
	autocmd!
	autocmd VimEnter * SendKittyOSC(SetEditorVar)
	autocmd VimLeavePre * SendKittyOSC(UnsetEditorVar)
	autocmd WinNew * timer_start(0, (_) => execute('close!', 'silent!'))
	autocmd TabNew * timer_start(0, (_) => execute('tabclose!', 'silent!'))
	autocmd TerminalOpen * {
			:set winfixbuf
			:setlocal termwinscroll=100000
			:nnoremap <silent> <buffer> q :qa!<CR>
			:nnoremap <silent> <buffer> i :qa!<CR>
			:xnoremap <silent> <buffer> <C-c> "+y
		}
augroup END

:set nomore
:set laststatus=0
:set showtabline=0
:set noswapfile
:set nobackup
:set nonumber norelativenumber
:set clipboard=unnamedplus
:setlocal bufhidden=hide
:packadd hlyank
:colorscheme default

# see https://github.com/vim/vim/blob/master/runtime/doc/wayland.txt#L56-L103
if has('wayland_clipboard') && !empty(v:wayland_display) && v:clipmethod ==# 'none'
	def Copy(reg: string, type: string, str: list<string>)
		var args = ["kitten", "clipboard", "--mime", $"text/plain;charset={&encoding}"]

		if reg == "*"
			args->add("-p")
		endif

		system(args, str)
	enddef

	def Paste(reg: string): tuple<string, list<string>>
		var args = ["kitten", "clipboard", "--mime", $"text/plain;charset={&encoding}", "-g"]

		if reg == "*"
			args->add("-p")
		endif

		var mode = visualmode()
		var text = systemlist(args)
		if empty(mode)
			return ('v', text)
		endif

		return (mode, text)
	enddef

	v:clipproviders.kitty = {
		available: () => !empty($KITTY_WINDOW_ID) && executable('kitten'),
		copy: {
			"+": Copy,
			"*": Copy
		},
		paste: {
			"+": Paste,
			"*": Paste
		}
	}

	&clipmethod = 'kitty'
endif

term_start('cat', {
	in_io: 'buffer',
	in_buf: bufnr(),
	term_name: 'kitty scrollback pager',
	term_finish: 'noclose',
	curwin: true,
	norestore: true,
	exit_cb: (job, _) => {
		term_wait(bufnr(), 0)
		var top = max([1, g:kitty_top])
		var row = max([1, g:kitty_cursor_row])
		var col = max([1, g:kitty_cursor_col])

		winrestview({
			topline: min([line('$'), top]),
			lnum: min([line('$'), top + row - 1]),
			col: col - 1})
	}
})
