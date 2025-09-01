vim9script

import "./quickfix.vim"
import "./log.vim"

export class Linter
	var cmd: list<string>
	var efm: list<string>

	def new(this.cmd, this.efm)
	enddef
endclass

export class Job
	static var _job: job

	static def _Callback(qf: quickfix.Quickfix, efm: string, chan: channel, msg: string)
		var job = ch_getjob(chan)
		if job->job_status() == 'fail'
			log.Error("Error: Job is failed on output callback.")
			return
		endif

		qf.SetList([], quickfix.Action.A, {
			efm: efm,
			lines: [msg]
		})
	enddef

	static def _ExitCb(qf: quickfix.Quickfix, bang: bool, job: job, _: number)
		if job->job_status() == 'fail'
			log.Error("Error: Job is failed on exit callback.")
			return
		endif

		qf.Window()
		if bang
			qf.JumpFirst()
		endif
	enddef

	static def Run(bang: bool)
		if _job->job_status() == "run"
			_job->job_stop()
			if _job->job_status() == "run" # when still running, will be kill it.
				_job->job_stop("kill")
			endif
		endif

		var linters = get(b:, 'linters', [])
		if linters == null_list
			log.Warn($"Warn: b:linters is empty")
			return
		endif

		var qf = quickfix.Quickfix.new()

		qf.SetList([], quickfix.Action.R)
		for linter in linters
			_job = job_start(linter.cmd, {
				callback: function(_Callback, [qf, join(linter.efm, ',')]),
				exit_cb: function(_ExitCb, [qf, bang]),
				in_io: 'null',
			})
		endfor
	enddef
endclass
