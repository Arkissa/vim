vim9script

import './quickfix.vim'
import './vim.vim'

# maybe more extensions for channel-mode?
export abstract class Job # {{{1
	var _job: job # {{{2
	var _cmd: string # {{{2
	var _location: bool # {{{2
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string) # {{{2
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel) # {{{2
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number) # {{{2

	def Status(): string # {{{2
		if this._job == null_job
			return "dead"
		endif

		return job_status(this._job)
	enddef

	def Stop() # {{{2
		if this._job != null_job
			job_stop(this._job)
		endif
	enddef

	def Info(): dict<any> # {{{2
		if this._job != null_job
			return job_info(this._job)
		endif

		return null_dict
	enddef

	def Run() # {{{2
		if this.Status() == "run"
			this.Stop()
		endif

		var qf = !this._location ? quickfix.Quickfix.new() : quickfix.Location.new(winnr())

		this._job = job_start(this._cmd, {
			callback: function(this.Callback, [qf]),
			close_cb: function(this.CloseCb, [qf]),
			exit_cb: function(this.ExitCb, [qf]),
			in_io: 'null'
		})
	enddef
endclass
