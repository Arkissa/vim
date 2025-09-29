vim9script

import './vim.vim'
import './quickfix.vim'
import './buffer.vim'
import './window.vim'
import './autocmd.vim'

type Autocmd = autocmd.Autocmd

# maybe more extensions for channel-mode?
export class Job
	var _job: job
	var _cmd: string

	def new(this._cmd)
		this._job = job_start(this._cmd)
	enddef

	def Status(): string
		if this._job == null_job
			return "dead"
		endif

		return job_status(this._job)
	enddef

	def GetChannel(): channel
		return job_getchannel(this._job)
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
endclass

export abstract class Quickfixer extends Job
	var _location: bool

	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel)
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)

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

export abstract class Prompt extends Job
	var prompt: buffer.Prompt
	static const AutocmdGroup = 'PromptJobGroup'

	abstract def Cmd(): string
	abstract def Prompt(): string
	abstract def Bufname(): string
	abstract def Callback(chan: channel, msg: string)

	def ExitCb(job: job, code: number)
		if code != 0
			echo $'Exit Code {code}'
		endif
	enddef

	def Send(msg: string)
		var chan = this.GetChannel()
		if chan != null_channel
			ch_sendraw(chan, $"{msg}\n")
		endif
	enddef

	def InterruptCb()
		this.Send('')
	enddef

	def Run()
		if this.Status() == 'run'
			this.Stop()
		endif

		this.prompt	= buffer.Prompt.new(this.Bufname())
		this.prompt.SetPrompt(this.Prompt())
		this.prompt.SetCallback(this.Send)
		this.prompt.SetInterrupt(this.InterruptCb)

		Autocmd.newMulti(['BufWipeout', 'BufDelete'])
			.Group(AutocmdGroup)
			.Pattern([this.prompt.bufnr->string()])
			.Once()
			.Callback(this.Stop)

		this._job = job_start(this.Cmd(), {
			pty: true,
			cwd: getcwd(),
			exit_cb: this.ExitCb,
			callback: this.Callback,
		})
	enddef
endclass
