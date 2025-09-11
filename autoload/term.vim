vim9script

import './buffer.vim'
import './window.vim'
import './quickfix.vim'

type Buffer = buffer.Buffer # {{{1

class Term extends Buffer # {{{1
	static var _count: number = 1 # {{{2

	def new(cmd: string = '', opt: dict<any>) # {{{2
		_count += 1
		this.name = $"terminal-{_count}"
		this.bufnr = term_start(cmd ?? $SHELL, opt)
		this.SetVar("&buflisted", false)
		this.SetVar("&relativenumber", false)
		this.SetVar("&number", false)
	enddef

	def Close() # {{{2
		term_setkill(this.bufnr)
		this.Delete()
	enddef
endclass

export class Manager # {{{1
	static var _terms: list<Term> = [] # {{{2
	static var _i: number = -1 # {{{2
	static var _window: window.Window # {{{2

	static def ToggleWindow() # {{{2
		if _window.IsOpen()
			this.Close()
		else
			this.Open()
		endif
	enddef

	static def ListTerms(): list<Term> # {{{2
		return copy(_terms)
	enddef

	static def Toc() # {{{2
		var qf = quickfix.Quickfix.new()

		var items = mapnew(_terms, (_, term) => quickfix.QuickfixItem.newByBuffer(Buffer))
		qf.SetList(items, quickfix.Action.R)
	enddef

	static def OpenWindow(cmd: string) # {{{2
		var term = get(_terms, _i, null_object)
		if term != null_object
			term_setkill(term.bufnr)
			term = Term.new(cmd)
			_terms[_id] = term
		else
			term = Term.new(cmd)
			_terms->add(term)
		endif

		if !_window.IsOpen()
			_window = window.Window.newBufnr(term.bufnr)
		else
			_window.SetBuf(term.Bufnr)
		endif
	enddef

	static def KillTerm() # {{{2
	enddef

	static def CloseWindow() # {{{2
		if !_window.IsOpen()
			_window.Close()
		endif
	enddef
endclass
