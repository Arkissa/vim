vim9script

import './vim.vim'
import './quickfix.vim'
import './buffer.vim'
import './window.vim'

# maybe more extensions for channel-mode?
export class Job # {{{1
	var _job: job # {{{2
	var _cmd: string # {{{2

	def new(this._cmd) # {{{2
		this._job = job_start(this._cmd)
	enddef # }}}

	def Status(): string # {{{2
		if this._job == null_job
			return "dead"
		endif

		return job_status(this._job)
	enddef # }}}

	def GetChannel(): channel # {{{2
		return job_getchannel(this._job)
	enddef # }}}

	def Stop() # {{{2
		if this._job != null_job
			job_stop(this._job)
		endif
	enddef # }}}

	def Info(): dict<any> # {{{2
		if this._job != null_job
			return job_info(this._job)
		endif

		return null_dict
	enddef # }}}
endclass # }}}

export abstract class Quickfixer extends Job # {{{1
	var _location: bool # {{{2

	abstract def Callback(qf: quickfix.Quickfixer, chan: channel, msg: string) # {{{2
	abstract def CloseCb(qf: quickfix.Quickfixer, chan: channel) # {{{2
	abstract def ExitCb(qf: quickfix.Quickfixer, job: job, code: number) # {{{2

	def Run() # {{{2
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
	enddef # }}}
endclass # }}}

export abstract class Prompt extends Job # {{{1
	var _promptBufferName: string # {{{2
	var _tmpfilename: string # {{{2
	var prompt: buffer.Prompt # {{{2

	abstract def Callback(chan: channel, msg: string) # {{{2
	abstract def Prompt(): string # {{{2

	def ExitCb(job: job, code: number) # {{{2
		this.Close()
		this.prompt.Delete()
	enddef

	def Send(msg: string)
		var chan = this.GetChannel()
		if chan != null_channel
			ch_sendraw(chan, $"{msg}\n")
		endif
	enddef

	def EnterCb(_: buffer.Prompt, msg: string) # {{{2
		this.Send(msg)
	enddef # }}}

	def InterruptCb(pt: buffer.Prompt) # {{{2
		this.Stop()
		pt.Delete()
	enddef # }}}

	def Run() # {{{2
		if this.Status() == 'run'
			this.Stop()
		endif

		this.prompt	= buffer.Prompt.new(this._promptBufferName)
		this.prompt.SetPrompt(this.Prompt())
		this.prompt.SetCallback(this.EnterCb)
		this.prompt.SetInterrupt(this.InterruptCb)

		this._job = job_start(this._cmd, {
			pty: true,
			cwd: getcwd(),
			exit_cb: this.ExitCb,
			callback: this.Callback,
		})
	enddef # }}}
endclass # }}}
