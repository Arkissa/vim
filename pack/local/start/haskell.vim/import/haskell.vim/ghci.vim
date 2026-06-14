vim9script

import 'log.vim'
import 'job.vim'
import 'vim.vim'
import 'timer.vim'
import 'buffer.vim'

import 'haskell.vim/request.vim'

export enum Cmd
	Stack("stack repl", ("--ghci-option=-ferror-spans", "--no-build", "--no-load")),
	Cabal("cabal repl", ("--ghc-option=-ferror-spans")),
	GHCi("ghci", ("-ferror-spans"))

	var Value: string
	var Args: tuple<string>
endenum

class Startup implements request.Command
	var _startup = [
		':set -v1',
		':set +c',
		':set prompt-cont ""',
		$':set prompt "{request.EOT}"',
	]

	def Cmd(): string
		return this._startup->join("\n")
	enddef
endclass

export class GHCi extends job.Job
	var _pending: request.Request
	var _queue: list<request.Request>

	def new(cmd: Cmd)
		this._cmd = cmd.Value
		this._opt = {
			callback: this.Callback,
			out_mode: "raw",
			err_mode: "raw",
			silent: true,
		}

		this.Run()
	enddef

	def Callback(chan: channel, chunk: string)
		if this._pending == null_object
			return
		endif

		if !this._pending.Callback(chunk)
			return
		endif

		this._pending = null_object
		if !this._queue->empty()
			this.Send(this._queue->remove(0))
		endif
	enddef

	def Send(req: request.Request)
		if this._pending != null_object
			this._queue->add(req)
			return
		endif

		this._pending = req
		ch_sendraw(this.GetChannel(), this._pending.Cmd() .. "\n")
	enddef

	def Restart()
		this.Stop()
		if this.Status() == 'run'
			this.Kill()
		endif

		this.Run()
	enddef

	def Run()
		super.Run()
		this.Send(request.Complete.new(Startup.new()))
	enddef
endclass
