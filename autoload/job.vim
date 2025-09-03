vim9script

import "./quickfix.vim"

export abstract class Job # maybe more extensions for channel-mode?
	static var _job: job
	abstract def Cmd(): string
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

	def Run(args: string)
		if this.Status() == "run"
			this.Stop()
		endif

		var param = expandcmd(args)

		var cmd = substitute(this.Cmd(), '\$\*', param, '')
		if cmd == this.Cmd()
			cmd = $"{trim(cmd)} {param}"
		endif

		var qf = quickfix.Quickfix.new()
		qf.SetList([], quickfix.Action.R)

		_job = job_start(cmd, {
			callback: function(this.Callback, [qf]),
			exit_cb: function(this.ExitCb, [qf]),
			in_io: 'null'
		})
	enddef
endclass
