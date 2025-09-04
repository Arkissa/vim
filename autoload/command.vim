vim9script

import "./quickfix.vim"
import "./log.vim"
import "./job.vim" as jb

export enum NArgs
	Zero("0")
	One("1")
	Star("*")
	Quest("?")
	Plus("+")

	var Value: string
endenum

export enum Count
	Zero("0")
	N("N")

	var Value: string
endenum

export enum Range
	Empty("")
	Persent("%")
	N("N")

	var Value: string
endenum

export enum Attr
endenum

export enum Addr
	Lines("lines")
	Arguments("arguments")
	Buffers("buffers")
	Loaded_buffers("loaded_buffers")
	Windows("windows")
	Tabs("tabs")
	Quickfix("quickfix")
	Other("other")

	var Value: string
endenum

# TODO command attributes
export class Execute
	var _cmd: list<string> = ["command"]
	var _mods: bool

	def Bang(): Execute
		add(this._cmd, "-bang")
		return this
	enddef

	def Register(): Execute
		add(this._cmd, "-register")
		return this
	enddef

	def Bar(): Execute
		add(this._cmd, "-bar")
		return this
	enddef

	def Buffer(): Execute
		add(this._cmd, "-buffer")
		return this
	enddef

	def KeepScript(): Execute
		add(this._cmd, "-keepscript")
		return this
	enddef

	def NArgs(n: NArgs = NArgs.Zero): Execute
		add(this._cmd, $"-nargs={n.Value}")
		return this
	enddef

	def Count(n: Count = Count.N): Execute
		add(this._cmd, $"-count=${n.Value}")
		return this
	enddef

	def Range(n: Range = Range.N): Execute
		var range = n != Range.Empty ? $"-range={n.Value}" : "-range"
		add(this._cmd, range)
		return this
	enddef

	def Addr(a: Addr): Execute
		add(this._cmd, $"-addr={a.Value}")
		return this
	enddef

	def Mods(): Execute
		this._mods = true
		return this
	enddef
endclass

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
