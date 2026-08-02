vim9script

if !has('terminal')
  echoerr 'kitty scrollback requires Vim +terminal'
  finish
endif

if $TERM != 'xterm-kitty'
	echoerr '$TERM must be kitty'
	finish
endif

g:helptoc = {
	shell_prompt: '^\$\s'
}

:set shortmess+=I
:setlocal bufhidden=wipe

augroup KittyScroolback
	autocmd!
	autocmd WinNew * timer_start(0, (_) => execute('close!', 'silent!'))
	autocmd TabNew * timer_start(0, (_) => execute('tabclose!', 'silent!'))
	autocmd TerminalOpen * {
			:set nomore
			:set nomodified
			:set nomodifiable
			:set laststatus=0
			:set showtabline=0
			:set noswapfile
			:set nobackup
			:set nonumber norelativenumber
			:set clipboard=unnamedplus
			:set termwinscroll=100000
			:set fillchars=eob:\ 
			:set scrolloff=1
			:set sidescrolloff=1

			:packadd hlyank
			:packadd helptoc
			:packadd matchit
			:packadd nohlsearch
			:colorscheme default
			:nnoremap <silent> q <CMD>qa!<CR>
			:nnoremap <silent> i <CMD>qa!<CR>
			:nnoremap <silent> <ESC> <CMD>qa!<CR>
			:xnoremap <silent> <C-c> "+y

			var mode = '\ Kitty\ VIM'
			execute($':set rulerformat=%{len(mode) * 2}({mode}%=%-12(%l,%c%V%)%P%)')
		}
augroup END

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

def g:ResetView(bufnr: number)
	term_wait(bufnr(), 0)
	execute($'buffer {bufnr}')
	var top = max([1, g:kitty_top])
	var row = max([1, g:kitty_cursor_row])
	var col = max([1, g:kitty_cursor_col])

	winrestview({
		topline: min([line('$'), top]),
		lnum: min([line('$'), top + row - 1]),
		col: col - 1})
	:set winfixbuf
enddef

term_start([
	'sed',
	'-e', ':trim',
	'-e', '/^[[:space:]]*$/{ $d; N; b trim; }',
	'-e', "s/$/\e[m/",
], {
	in_io: 'file',
	in_name: '/dev/fd/63',
	term_name: 'kitty scrollback pager',
	term_finish: 'open',
	term_opencmd: 'call g:ResetView(%d)',
	hidden: true,
	norestore: true,
})
