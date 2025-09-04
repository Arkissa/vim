vim9script

import "./quickfix.vim"

export abstract class Job # maybe more extensions for channel-mode?
	static var _job: job
	var _cmd: string
	abstract def Callback(qf: quickfix.Quickfix, chan: channel, msg: string)
	abstract def ExitCb(qf: quickfix.Quickfix, job: job, code: number)

	def Status(): string
		if _job == null_job
			return "dead"
		endif

		return job_status(_job)
	enddef

	def Stop()
		if _job != null_job
			job_stop(_job)
		endif
	enddef

	def Run()
		if this.Status() == "run"
			this.Stop()
		endif

		var qf = quickfix.Quickfix.new()
		qf.SetList([], quickfix.Action.R)

		_job = job_start(this._cmd, {
			callback: function(this.Callback, [qf]),
			exit_cb: function(this.ExitCb, [qf]),
			in_io: 'null'
		})
	enddef
endclass
