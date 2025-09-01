vim9script

import "./quickfix.vim"
import "./log.vim"

export class Lint
	var cmd: list<string>
	var efm: list<string>

	def new(this.cmd, this.efm)
	enddef
endclass

export class Manager
	static var _job: job

	static def _Callback(qf: quickfix.Quickfix, efm: string, chan: channel, msg: string)
		var job = ch_getjob(chan)
		if job->job_status() == 'fail'
			log.Error("Error: Job is failed on output callback.")
			return
		endif

		qf.SetList([], quickfix.Action.A, {
			efm: efm,
			lines: msg->split('\n')
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

	static def RunLint(bang: bool)
		var ftLinters = get(g:, 'Linters', {})
		if ftLinters == null_dict
			return
		endif

		var ft = &filetype
		if !ftLinters->has_key(ft)
			log.Warn($"Warn: unsupported {ft} filetype")
			return
		endif

		var linters = ftLinters[ft]

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
