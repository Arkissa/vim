vim9script

import 'vim.vim'
import 'log.vim'
import 'timer.vim'
import 'expect.vim'
import 'buffer.vim'
import 'window.vim'
import 'autocmd.vim'
import 'quickfix.vim'

type Timer = timer.Timer
type State = expect.State
type Expect = expect.Expect
type Autocmd = autocmd.Autocmd

export class Job
	var _job: job
	var _cmd: string
	var _opt: dict<any> = {}
	var _expect: Expect

	def new(this._cmd, this._opt)
	enddef

	def _JobRunPost()
		var t = Timer.new(500, (_t) => {
			Autocmd.Do('', 'User', ['JobRunPost'])

			_t.Stop()
		})

		def Cb(F: func(channel, string), ch: channel, text: string)
			if !t.Stoped()
				t.Reset()
			endif

			call(F, [ch, text])
		enddef

		if has_key(this._opt, 'err_cb')
			this._opt.err_cb = funcref(Cb, [this._opt.err_cb])
		endif

		if has_key(this._opt, 'out_cb')
			this._opt.out_cb = funcref(Cb, [this._opt.out_cb])
		endif

		if has_key(this._opt, 'callback')
			this._opt.callback = funcref(Cb, [this._opt.callback])
		endif
	enddef

	def _Expect()
		this._opt.err_mode = 'raw'
		this._expect = Expect.new()

		def Cb(ch: channel, text: string)
			this._expect.Handle(text)
		enddef

		if has_key(this._opt, 'err_cb')
			this._opt.err_cb = Cb
		endif

		if has_key(this._opt, 'out_cb')
			this._opt.out_cb = Cb
		endif

		if has_key(this._opt, 'callback')
			this._opt.callback = Cb
		endif
	enddef

	def Run()
		this.Stop()

		if exists('#User#JobRunPost')
			this._JobRunPost()
		endif

		if get(this._opt, 'out_mode', '') == 'raw'
			this._Expect()
		endif

		if exists('#User#JobRunPre')
			Autocmd.Do('', 'User', ['JobRunPre'])
		endif

		this._job = job_start(this._cmd, this._opt)

		:redraw
		echo $":!{this._cmd}"
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
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number)
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel)
	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string)

	def Run()
		var qf = !this._location
			? quickfix.Quickfix.new()
			: quickfix.Location.new(winnr())

		this._cmd = this.Cmd()
		this._opt->extend({
			callback: function(this.Callback, [qf]),
			close_cb: function(this.CloseCb, [qf]),
			exit_cb: function(this.ExitCb, [qf]),
		}, 'force')

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
		this._opt->extend({
			pty: true,
			cwd: getcwd(),
			exit_cb: this.ExitCb,
			callback: this.Callback,
		}, 'force')

		super.Run()
	enddef
endclass
