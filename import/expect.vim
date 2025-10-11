vim9script

import 'vim.vim'
import 'pair.vim'

const nil = pair.nil

const MAX_BUFFER_LINE = 100

class State
	var patterns: list<tuple<string, func>>

	def new(this.patterns)
	enddef
endclass

class Expect
	var _states: Pair = nil
	var _bufferLines: list<string>

	def State(): State
		if this._states->empty()
			return null_object
		endif

		return pair.Car(this._states)
	enddef

	def Pop(): State
		defer (() => {
			this._states = pair.Cdr(this._states)
		})()

		return pair.Car(this._states)
	enddef

	def Switch(state: State): State
		defer (() => {
			this._states = pair.Cons(state, pair.Cdr(this._states))
		})()

		return pair.Car(this._states)
	enddef

	def Push(state: State)
		this._states = pair.Cons(this._states, state)
	enddef

	def Handle(lines: string)
		var lines_ = lines
		if lines_->empty()
			return
		endif

		if lines_[-1 : ] !~ "\\v\r+\n" && !this._bufferLines->empty()
			lines_ ..= this._bufferLines[-1]
			remove(this._bufferLines[-1])
		endif
	enddef
endclass
