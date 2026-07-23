vim9script

if !has('terminal')
  echoerr 'kitty scrollback requires Vim +terminal'
  finish
endif

if $TERM != 'xterm-kitty'
	echoerr '$TERM must be kitty'
	finish
endif

const SetEditorVar = $"\e]1337;SetUserVar=in_editor={base64_encode(str2blob(['1']))}\a"
const UnsetEditorVar = "\e]1337;SetUserVar=in_editor\a"

def SendKittyOSC(seq: string)
	writefile([seq], '/dev/tty', 'b')
enddef

def RejectExtraWindow(_)
  if win_getid() == g:kitty_main_winid
    return
  endif

  if win_gettype() ==# 'popup'
    return
  endif

  if winnr('$') == 1
    silent! tabclose!
  else
    silent! close!
  endif
enddef

# Disable any window and tab to open.
augroup KittyScroolback
	autocmd!
	autocmd VimEnter * SendKittyOSC(SetEditorVar)
	autocmd VimLeavePre * SendKittyOSC(UnsetEditorVar)
	autocmd WinNew * timer_start(0, RejectExtraWindow)
	autocmd TabNew * timer_start(0, RejectExtraWindow)
	autocmd WinEnter * timer_start(0, RejectExtraWindow)
augroup END

:set nomore
:set laststatus=0
:set showtabline=0
:set noswapfile
:set nobackup
:setlocal nomodified
:setlocal bufhidden=hide
:packadd hlyank
:colorscheme default
:setlocal termwinscroll=100000
:setlocal nonumber norelativenumber
:nnoremap <silent> q :qa!<CR>
:nnoremap <silent> i :qa!<CR>
:xnoremap <silent> <C-c> "+y

&clipboard = 'unnamedplus'

if has('wayland_clipboard') && !empty(v:wayland_display) && v:clipmethod ==# 'none'
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

	&clipmethod = 'wl_clipboard'
endif

def RestoreKittyView(_)
  var job = term_getjob(g:kitty_term_buf)

  if job_status(job) ==# 'run'
    timer_start(10, RestoreKittyView)
    return
  endif

  term_wait(g:kitty_term_buf, 30)

  var top = max([1, g:kitty_top])
  var row = max([1, g:kitty_cursor_row])
  var col = max([1, g:kitty_cursor_col])

  var target = min([
	  line('$'),
	  top + row - 1,
  ])

  winrestview({
	  topline: min([line('$'), top]),
	  lnum: target,
	  col: col - 1,
  })
enddef

execute(':%terminal ++curwin ++noclose cat')

g:kitty_term_buf = bufnr()
g:kitty_main_winid = win_getid()

:set winfixbuf

timer_start(10, RestoreKittyView)
