vim9script

import 'command.vim'
import 'quickfix.vim'

type ErrorFormat = command.ErrorFormat

export class Make extends ErrorFormat
	static var _history: list<Make> = []

	def Cmd(): string
		return this.Expandcmd(&makeprg)
	enddef

	def Efm(): string
		return &errorformat
	enddef

	def Run()
		_history->add(this)
		super.Run()
	enddef

	static def GetHistory(): list<Make>
		return _history->copy()
	enddef

	def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)
		var info = this.Info()

		_history->remove(_history->indexof((_, m) => {
			var i = m.Info()
			return i.process == info.process
		}))

		super.ExitCb(qf, job, code)
	enddef
endclass
