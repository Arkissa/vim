vim9script

import './buffer.vim'
import './window.vim'
import './quickfix.vim'
import './autocmd.vim'

type Buffer = buffer.Buffer # {{{1
type Autocmd = autocmd.Autocmd # {{{1

class Term extends Buffer # {{{1

	def new(cmd: string, opt: dict<any>) # {{{2
		this.bufnr = term_start(cmd, opt)
		this.name = cmd
		this.SetVar("&buflisted", false)
		this.SetVar("&relativenumber", false)
		this.SetVar("&number", false)
	enddef

	def Close() # {{{2
		term_setkill(this.bufnr, 'kill')
		this.Delete()
	enddef # }}}
endclass

var terms: list<Term> = [] # {{{2
var current: Term # {{{2
var win: window.Window # {{{2
const group = "TermManager"

export class Manager # {{{1
	static def ToggleWindow(pos: string = '') # {{{2
		if win != null_object && win.IsOpen()
			_CloseWindow()
		else
			_OpenWindow(pos)
		endif
	enddef # }}}

	static def ListTerms(): list<Term> # {{{2
		return copy(terms)
	enddef # }}}

	static def NewTerm(cmd: string = ''): Term # {{{2
		var term = Term.new(cmd ?? $SHELL, {
			hidden: true,
			term_kill: 'kill',
			term_finish: 'close',
			exit_cb: (_, _) => {
				var old = current
				Manager.Slide(1)
				terms->filter((_, term) => term.bufnr != old.bufnr)

				if empty(terms)
					current = null_object
				endif
			}
		})

		if win != null_object && win.IsOpen()
			win.SetBuf(term.bufnr)
		endif
		terms->add(term)

		return term
	enddef # }}}

	static def TermsToc() # {{{2
		var qf = quickfix.Quickfix.new()
		var items = terms->mapnew((_, term) => quickfix.QuickfixItem.newByBuffer(term))

		qf.SetList(items, quickfix.Action.R)
	enddef # }}}

	static def _OpenWindow(pos: string = '') # {{{2
		if current == null_object
			current = NewTerm()
		endif

		win = window.Window.newByBufnr(current.bufnr, pos)
		Autocmd.new('WinClosed')
			.Group(group)
			.Pattern([win.winnr->string()])
			.Replace()
			.Callback(() => {
				win = null_object
			})

	enddef # }}}

	static def Slide(offset: number)
		for [i, term] in terms->items()
			if term.bufnr == current.bufnr
				current = terms[(i + offset) % len(terms)]

				if win != null_object && win.IsOpen()
					win.SetBuf(current.bufnr)
				endif

				return
			endif
		endfor

		current = null_object
	enddef

	static def KillCurrentTerm() # {{{2
		if current != null_object
			current.Close()
		endif
	enddef # }}}

	static def KillAllTerms() # {{{2
		terms->foreach((_, term) => {
			term.Close()
		})

		terms = []
		current = null_object
		_CloseWindow()
	enddef # }}}

	static def _CloseWindow() # {{{2
		if win != null_object && win.IsOpen()
			win.Close()
		endif
	enddef # }}}
endclass
