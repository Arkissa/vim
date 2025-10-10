vim9script

import 'vim.vim'
import 'log.vim'
import 'timer.vim'
import 'buffer.vim'
import 'window.vim'
import 'autocmd.vim'
import 'quickfix.vim'

type Autocmd = autocmd.Autocmd
type Timer = timer.Timer

export class Job
	var _job: job
	var _cmd: string
	var _opt: dict<any>

	def new(this._cmd, this._opt)
	enddef

	def Run()
		this.Stop()

		if exists('#User#JobRunPost')
			var t = Timer.new(500, (_t) => {
				Autocmd.Do('', 'User', ['JobRunPost'])

				_t.Stop()
			})

			if has_key(this._opt, 'callback')
				var C = this._opt.callback
				this._opt.callback = (ch, text) => {
					if !t.Stoped()
						t.Reset()
					endif

					C(ch, text)
				}
			endif

			if has_key(this._opt, 'err_cb')
				var E = this._opt.err_cb
				this._opt.err_cb = (ch, text) => {
					if !t.Stoped()
						t.Reset()
					endif

					E(ch, text)
				}
			endif

			if has_key(this._opt, 'out_cb')
				var O = this._opt.out_cb
				this._opt.out_cb = (ch, text) => {
					if !t.Stoped()
						t.Reset()
					endif

					O(ch, text)
				}
			endif
		endif

		if exists('#User#JobRunPre')
			Autocmd.Do('', 'User', ['JobRunPre'])
		endif

		this._job = job_start(this._cmd, this._opt)
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

	abstract def Cmd(): string
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel)
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)

	def Run()
		var qf = !this._location ? quickfix.Quickfix.new() : quickfix.Location.new(winnr())

		this._cmd = this.Cmd()
		this._opt = {
			callback: function(this.Callback, [qf]),
			close_cb: function(this.CloseCb, [qf]),
			exit_cb: function(this.ExitCb, [qf]),
			in_io: 'null'
		}

		super.Run()
	enddef
endclass

export abstract class Prompt extends Job
	var prompt: buffer.Prompt
	static const Group = 'PromptJobGroup'

	abstract def Cmd(): string
	abstract def Prompt(): string
	abstract def Bufname(): string
	abstract def Callback(chan: channel, text: string)

	def ExitCb(job: job, code: number)
		if code != 0
			return
		endif

		if this.prompt.IsExists()
			this.prompt.Delete()
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
		this.prompt	= buffer.Prompt.new(this.Bufname())
		this.prompt.SetCallback(this.Send)
		this.prompt.SetPrompt(this.Prompt())
		this.prompt.SetInterrupt(this.InterruptCb)

		Autocmd.newMulti(['BufWipeout', 'BufDelete'])
			.Group(Group)
			.Pattern([this.prompt.bufnr->string()])
			.Once()
			.Callback(this.Stop)

		this._cmd = this.Cmd()
		this._opt = {
			pty: true,
			cwd: getcwd(),
			exit_cb: this.ExitCb,
			callback: this.Callback,
		}

		super.Run()
	enddef
endclass
