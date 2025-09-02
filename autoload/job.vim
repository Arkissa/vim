vim9script

import "./quickfix.vim"

export abstract class Job # maybe more extensions for channel-mode?
	var job: job
	abstract def Cmd(): string
	abstract def Callback(qf: quickfix.Quickfix, chan: channel, msg: string)
	abstract def ExitCb(qf: quickfix.Quickfix, job: job, code: number)

	def Status(): string
		if this.job == null_job
			return "dead"
		endif

		return job_status(this.job)
	enddef

	def Stop()
		if this.job != null_job && this.Status() == "run"
			job_stop(job)
		endif
	enddef

	def Run(args: string)
		var cmd = substitute(this.Cmd(), '\$\*', args, '')
		if cmd == this.Cmd()
			cmd = $"{trim(cmd)} {args}"
		endif

		cmd = expand(cmd)
		echom cmd

		var qf = quickfix.Quickfix.new()
		qf.SetList([], quickfix.Action.R)

		this.job = job_start(cmd, {
			callback: function(this.Callback, [qf]),
			exit_cb: function(this.ExitCb, [qf])
		})
	enddef
endclass
