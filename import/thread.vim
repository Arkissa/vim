vim9script

export abstract class Void # {{{1
	def string(): string # {{{2
		return 'void'
	enddef # }}}
endclass # }}}

class Void_ extends Void # {{{1
endclass # }}}

class Exception
	const _exception: string

	def new(this._exception)
	enddef

	def string(): string
		return this._exception
	enddef
endclass

const void = Void_.new()

export interface Thread
endinterface

enum ThreadStatus
	Running,
	Done
endenum

class Thread_ implements Thread
	var id = id(this)
	var ret: any
	var status = ThreadStatus.Running

	static const maxDelay = 64

	def new(Fn: func, ...args: list<any>)
		timer_start(0, (_) => {
			try
				if typename(Fn) =~# '^func(.\{-\}):'
					this.ret = call(Fn, args)
				else
					call(Fn, [])
					this.ret = void
				endif

				this.status = ThreadStatus.Done
			catch
				this.ret = Exception.new($'thread {this.id} got exception')
				this.status = ThreadStatus.Done
				throw substitute(v:exception, '^Vim:\{-\}:', '', '')
			endtry
		})
	enddef
endclass

export def Fork(Fn: func, ...args: list<any>): Thread
	return call(function(Thread_.new, [Fn]), args)
enddef

export def Wrap(Fn: func): func(...list<any>)
	return (...args: list<any>) => {
		if typename(Fn) =~# '^func(.\{-\}):'
			call(Fn, args)
		else
			call(Fn, [])
		endif
	}
enddef

export def Join(thread: Thread): any
	var _thread: Thread_ = <Thread_>thread

	var delay = 1
	while _thread.status == ThreadStatus.Running
		execute($'sleep {delay}m', 'silent')
		delay = min([delay << 1, Thread_.maxDelay])
	endwhile

	var val = _thread.ret
	if type(val) == v:t_object && instanceof(val, Exception)
		throw val->string()
	endif

	return val
enddef
