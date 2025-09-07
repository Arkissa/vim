vim9script

import './quickfix.vim'
import './vim.vim'

export abstract class Job # maybe more extensions for channel-mode?
	var _job: job
	var _cmd: string
	var _location: bool
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel)
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)

	def Status(): string
		if this._job == null_job
			return "dead"
		endif

		return job_status(this._job)
	enddef

	def Stop()
		if this._job != null_job
			job_stop(this._job)
		endif
	enddef

	def Info(): dict<any>
		if this._job != null_job
			return job_info(this._job)
		endif

		return null_dict
	enddef

	def Run()
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
