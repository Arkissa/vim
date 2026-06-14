vim9script

import 'timer.vim'

export const EOT = "\x04"

export interface Command
	def Cmd(): string
endinterface

export interface LiveHandle extends Command
	def Handle(chunk: string)
endinterface

export interface Request
	def Cmd(): string
	def Callback(chunk: string): bool
endinterface

interface LogSink
	def Write(line: string)
endinterface

class Log implements Request
	var _request: Request
	var _sink: LogSink

	def new(this._request, this._sink)
	enddef

	def Cmd(): string
		return this._request.Cmd()
	enddef

	def Callback(chunk: string): bool
		return this._request.Callback(chunk)
	enddef
endclass

export class Live implements Request
	var _handle: LiveHandle
	var _done: bool

	def new(this._handle)
	enddef

	def Cmd(): string
		return this._handle.Cmd()
	enddef

	def Callback(chunk: string): bool
		this._done = chunk[-1] == EOT

		if this.Finished()
			chunk = chunk[: -2]
		endif

		this._handle.Handle(chunk)
		return this.Finished()
	enddef

	def Finished(): bool
		return this._done
	enddef
endclass

const maxDelay = 64

export class Complete implements Request
	var _cmd: Command
	var _body: string
	var _done: bool

	def new(this._cmd)
	enddef

	def Cmd(): string
		return this._cmd.Cmd()
	enddef

	def Callback(chunk: string): bool
		this._done = chunk[-1] == EOT

		this._body ..= this._done
			? chunk[: -2]
			: chunk

		return this._done
	enddef

	def Body(timeout: number = -1): any
		var delay = 1
		var running = true
		if timeout != -1
			timer.Timer.new(timeout, (_) => {
				running = false
			}).Start()
		endif

		while !this._done && running
			execute($"sleep {delay}m", "silent")

			delay = min([delay << 1, maxDelay])
		endwhile

		if !running
			throw 'wait for body timeout.'
		endif

		return this._body
	enddef
endclass

export class Discard implements Request
	var _cmd: Command

	def new(this._cmd)
	enddef

	def Cmd(): string
		return this._cmd.Cmd()
	enddef

	def Callback(chunk: string): bool
		return chunk[-1] == EOT
	enddef
endclass

