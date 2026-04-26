vim9script

import 'job.vim'
import 'timer.vim'
import 'log.vim'

const EOT = {
	escape: '\x04',
	raw: "\x04"
}
const maxDelay = 64
const maxWait = 200

interface Awaitable
	def IsDone(): bool
	def Result(): any
endinterface

export abstract class Request
	abstract def Cmd(): string

	def Live(_: string)
	enddef

	def Complete(_: string)
	enddef
endclass

export abstract class SyncRequest extends Request implements Awaitable
	abstract def Cmd(): string
	abstract def IsDone(): bool
	abstract def Result(): any
endclass

export enum Cmd
	Stack("stack repl"),
	Cabal("cabal repl"),
	GHCi("ghci")

	var Value: string
endenum

class Startup extends Request
	var _startup = [
		':set -v1',
		':set +c',
		':set prompt-cont ""',
		$':set prompt "{EOT.escape}"',
	]

	def Cmd(): string
		return this._startup->join("\n")
	enddef

	def Live(_: string)
	enddef

	def Complete(_: string)
		log.PopInfo("ghci startuped.")
	enddef
endclass

def Await(a: Awaitable, timeout: number = -1): any
	var delay = 1
	var running = true
	if timeout != -1
		timer.Timer.new(timeout, (_) => {
			running = false
		}).Start()
	endif

	while !a.IsDone() && running
		execute($"sleep {delay}m", "silent")

		delay = min([delay << 1, maxDelay])
	endwhile

	return a.Result()
enddef

export class GHCi extends job.Job
	var _msg: Request
	var _queue: list<Request>
	var _response: string

	def new(cmd: Cmd)
		this._opt = {
			callback: this.Callback,
			out_mode: "raw",
			err_mode: "raw",
			silent: true,
		}

		this._cmd = cmd.Value
		this.OnRunPost((_) => {
			this.Send(Startup.new())
		})
	enddef

	def Callback(chan: channel, chunk: string)
		if this._msg == null_object
			return
		endif

		this._response ..= chunk
		if this._response[-1] != EOT.raw
			this._msg.Live(chunk)
			return
		endif

		this._msg.Live(chunk[: -2])
		this._msg.Complete(this._response[: -2])
		this._response = ""

		this._msg = null_object
		if !this._queue->empty()
			this.Send(this._queue->remove(0))
		endif
	enddef

	def Send(msg: Request)
		if this._msg != null_object
			this._queue->add(msg)
			return
		endif

		this._msg = msg
		ch_sendraw(this.GetChannel(), this._msg.Cmd() .. "\n")
	enddef

	def SyncSend(request: SyncRequest): any
		this.Send(request)

		return Await(request, maxWait)
	enddef

	def Busy(): bool
		return this._msg != null_object
	enddef
endclass
