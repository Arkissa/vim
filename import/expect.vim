vim9script

import 'vim.vim'

type List = vim.List
type TupleList = vim.TupleList

const MAX_BUFFER_LINE = 100

export class State
	var patterns: list<tuple<string, func>>

	def new(this.patterns)
	enddef
endclass

export class Expect
	var _states: TupleList = ()
	var _linesBuffer: list<string> = []
	var _isCompleted: bool = true

	def State(): State
		if this._states->empty()
			return null_object
		endif

		return List.Head(this._states)
	enddef

	def Pop(): State
		defer (() => {
			this._states = List.Tail(this._states)
		})()

		return List.Head(this._states)
	enddef

	def Switch(state: State): State
		defer (() => {
			this._states = (state, List.Tail(this._states))
		})()

		return List.Head(this._states)
	enddef

	def Push(state: State)
		this._states = (this._states, state)
	enddef

	def Handle(lines: string)
		var lines_ = lines
		if lines_->empty()
			return
		endif

		var linesBuffer = this._linesBuffer
		if !this._isCompleted && !linesBuffer->empty()
			lines_ = linesBuffer[-1] .. lines_
			remove(linesBuffer, 0)
		endif

		this._isCompleted = lines_ =~# "\r\\?\n$"
		linesBuffer += lines_->split("\r\\?\n")

		while !linesBuffer->empty()
			var idx = this._Parse(linesBuffer)
			if idx == -1
				break
			endif

			linesBuffer = linesBuffer[idx + 1 : ]
		endwhile

		while len(linesBuffer) > MAX_BUFFER_LINE
			remove(linesBuffer, 0)
		endwhile

		this._linesBuffer = linesBuffer
	enddef

	def _Parse(lines: list<string>): number
		if lines->empty()
			return -1
		endif

		var state = this.State()
		if state == null_object
			return -1
		endif

		for [pattern, handler] in state.patterns
			var matchs = matchlist(lines, pattern)
			if !matchs->empty()
				call(handler, matchs[1 : ]->filter((_, s) => s != ''))
				return match(lines, pattern)
			endif
		endfor

		return -1
	enddef
endclass
