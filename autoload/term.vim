vim9script

import './buffer.vim'
import './window.vim'
import './quickfix.vim'
import './autocmd.vim' as au
import './vim.vim'

type Buffer = buffer.Buffer # {{{1
type Autocmd = au.Autocmd # {{{1

class Term extends Buffer # {{{1
	def new(cmd: string, opt: dict<any>) # {{{2
		this.bufnr = term_start(cmd, opt)
		this.name = cmd
		this.SetVar("&buflisted", false)
		this.SetVar("&relativenumber", false)
		this.SetVar("&number", false)
	enddef # }}}

	def Stop()
		job_stop(term_getjob(this.bufnr), 'kill')
	enddef
endclass

var terms: list<Term> = [] # {{{2
var current: Term # {{{2
var win: window.Window # {{{2
const group = "TermManager"

export class Manager # {{{1
	static const _opts = {
		hidden: true,
		term_kill: 'term',
		term_finish: 'close',
		close_cb: (_) => {
			var old = current
			Manager.Slide(1)
			terms->filter((_, term) => term.bufnr != old.bufnr)

			if empty(terms)
				current = null_object
			endif
		}
	}
	static var autocmd = Autocmd.new('WinClosed').Group(group).Replace().Once()

	static def ToggleWindow(cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if win != null_object && win.IsOpen()
			win.Close()
		else
			NewTerm(cmd, pos, count)
		endif
	enddef # }}}

	static def ListTerms(): list<Term> # {{{2
		return copy(terms)
	enddef # }}}

	static def Current(): Term
		return current
	enddef

	static def NewTerm(cmd: string = '', pos: string = '', count: number = 0) # {{{2
		if current == null_object || win != null_object
			current = Term.new(cmd ?? $SHELL, _opts)
		endif

		if win == null_object
			win = window.Window.new(pos, count)
		endif

		autocmd.Pattern([win.winnr->string()])
			.Callback(() => {
				win = null_object
			})

		win.SetBuf(current.bufnr)
		terms->add(current)
	enddef # }}}

	static def TermsToc() # {{{2
		var qf = quickfix.Quickfix.new()
		var items = terms->mapnew((_, term) => quickfix.QuickfixItem.newByBuffer(term))

		qf.SetList(items, quickfix.Action.R)
	enddef # }}}

	static def Slide(offset: number) # {{{2
		for [i, term] in terms->items()
			if term.bufnr == current.bufnr
				var index = (i + offset) % len(terms)
				echom index
				current = terms[index]

				if win != null_object
					win.SetBuf(current.bufnr)
				endif

				return
			endif
		endfor

		current = null_object
	enddef # }}}

	static def KillCurrentTerm() # {{{2
		if current != null_object
			if len(terms) != 1
				current.Stop()
			else
				current.Delete()
			endif
		endif
	enddef # }}}

	static def KillAllTerms() # {{{2
		terms->foreach((_, term) => {
			term.Delete()
		})

		terms = []
		current = null_object
		_CloseWindow()
	enddef # }}}

	static def _CloseWindow() # {{{2
		if win != null_object
			win.Close()
		endif
	enddef # }}}
endclass
