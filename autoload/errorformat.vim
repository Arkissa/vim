vim9script

import "./quickfix.vim"
import "./log.vim"
import "./job.vim" as jb

export abstract class Command extends jb.Job
	var _bang: bool

	abstract def Cmd(): string
	abstract def Efm(): string

	def Callback(qf: quickfix.Quickfix, chan: channel, msg: string)
		var job = ch_getjob(chan)
		var jobinfo = job->job_info()
		if jobinfo.status == 'fail'
			log.Error("Error: Job is failed on output callback.")
			return
		endif

		qf.SetList([], quickfix.Action.A, {
			efm: this.Efm(),
			lines: [msg],
			title: jobinfo.cmd->join(' ')
		})
	enddef

	def ExitCb(qf: quickfix.Quickfix, job: job, _: number)
		if job->job_status() == 'fail'
			log.Error("Error: Job is failed on exit callback.")
			return
		endif

		qf.Window()
		if this._bang
			qf.JumpFirst()
		endif
	enddef
endclass
