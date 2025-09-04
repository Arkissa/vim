vim9script

import "./quickfix.vim"
import "./log.vim"
import "./job.vim" as jb

# TODO command attributes

export abstract class Command extends jb.Job
	var _attr: dict<any>

	abstract def Cmd(): string
	abstract def Callback(qf: quickfix.Quickfix, chan: channel, msg: string)

	def SetAttr(attr: dict<any>): Command
		this._attr = attr
		return this
	enddef

	def ExitCb(qf: quickfix.Quickfix, job: job, code: number)
		if job->job_status() == 'fail'
			log.Error("Error: Job is failed on exit callback.")
			return
		endif

		qf.Window()
		if this._attr.bang
			qf.JumpFirst()
		endif

		echo $"Exit code: {code}"
	enddef

	def Run()
		var param = expandcmd(this._attr.args)
		var cmd = this.Cmd()
		var sep = '\$\*'

		var expandedCmd: string
		if cmd =~ sep
			expandedCmd = substitute(cmd, sep, param, '')
		else
			expandedCmd = $"{trim(cmd)} {param}"
		endif

		this._cmd = expandedCmd

		super.Run()
	enddef
endclass

export abstract class ErrorFormat extends Command
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
endclass

# TODO Create a command function
