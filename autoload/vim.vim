vim9script

export def Cmd(s: list<string>): string # {{{1
	return s->join(' ')
enddef # }}}

export def Option(s: list<string>): string # {{{1
	return s->join(',')
enddef # }}}

export abstract class Void # {{{1
	def string(): string # {{{2
		return 'void'
	enddef # }}}
endclass # }}}

class SingleVoid extends Void # {{{1
endclass # }}}

export const void = SingleVoid.new() # {{{1

export class Ring # {{{1
	var _list: list<any>
	var _i: number

	def new(a: any) # {{{2
		this._list = [a]
	enddef # }}}

	def len(): number # {{{2
		if this == null_object
			return 0
		endif

		return len(this._list)
	enddef # }}}

	def empty(): bool # {{{2
		return this->len() == 0
	enddef # }}}

	def Current<T>(): T # {{{2
		if this->empty()
			return null_object
		endif

		return this._list[this._i]
	enddef # }}}

	def Remove<T>(): T # {{{2
		if this->empty()
			return null_object
		endif

		var c = remove(this._list, this._i)
		if this->empty()
			this._i = 0
			return c
		endif

		this._i %= this->len()

		return c
	enddef # }}}

	def Add<T>(t: T) # {{{2
		if this->empty()
			add(this._list, t)
		else
			insert(this._list, t, (this._i + 1))
		endif
		this._i = (this._i + 1) % this->len()
	enddef # }}}

	def SlideLeft(): Ring # {{{2
		this._i = (this._i - 1) % this->len()
		return this
	enddef # }}}

	def SlideRight(): Ring # {{{2
		this._i = (this._i + 1) % this->len()
		return this
	enddef # }}}

	def ToList<T>(): list<T> # {{{2
		return copy(this._list)
	enddef # }}}

	def ForEach(F: func(any)) # {{{2
		for item in this._list
			F(item)
		endfor
	enddef # }}}
endclass # }}}

export class IncID # {{{1
	var _id = -1

	def ID(): number # {{{2
		this._id += 1
		return this._id
	enddef # }}}
endclass # }}}

export class Exception # {{{1
	var _exception: string # {{{2

	def new(this._exception) # {{{2
	enddef # }}}

	def string(): string # {{{2
		return this._exception
	enddef # }}}
endclass # }}}

export class TimeoutException extends Exception # {{{1
	def new(s: string) # {{{2
		this._exception = $'Timeout: {s}'
	enddef # }}}
endclass # }}}

export class CoroutineDeadException extends Exception # {{{1
	def new(id: number) # {{{2
		this._exception = $'Dead: can''t waiting for already dead with {id} coroutine .'
	enddef # }}}
endclass # }}}

export enum CoroutineStatus # {{{1
	Running,
	Suspended,
	Dead
endenum # }}}

final coroutine = IncID.new()

export class Coroutine # {{{1
	var id = coroutine.ID()
	var delay = 0
	var Func: func
	var status = CoroutineStatus.Suspended
	var _ret: dict<any> = {}

	def new(F: func, ...args: list<any>) # {{{2
		this.Func = () => {
			this.status = CoroutineStatus.Running

			try
				if typename(F) =~# '^func(.\{-\}):'
					this._ret[this.id] = call(F, args)
				else
					call(F, args)
					this._ret[this.id] = void
				endif
			catch
				this._ret[this.id] = Exception.new(substitute(v:exception, '^Vim:', '', ''))
			finally
				this.status = CoroutineStatus.Dead
			endtry
		}
	enddef # }}}

	def SetDelay(time: number): Coroutine # {{{2
		this.delay = time
		return this
	enddef # }}}

	# if you is not Await, don't use it.
	def UnsafeHookReturn(d: dict<any>) # {{{2
		this._ret = d
	enddef # }}}
endclass # }}}

export abstract class Async # {{{1
	def Await<T>(co: Coroutine, timeout: tuple<number, T> = null_tuple): T # {{{2
		var ret = {}
		co.UnsafeHookReturn(ret)

		if co.status == CoroutineStatus.Suspended
			AsyncIO.Run(co)
		endif

		var timer = timeout != null_tuple
			? timer_start(timeout[0], (_) => {
				if co.status == CoroutineStatus.Running
					ret[co.id] = timeout[1]
				endif
			})
			: -1

		while !has_key(ret, co.id)
			:sleep 50m
		endwhile

		timer_stop(timer)

		var val = ret[co.id]
		if type(val) == type(null_object) && instanceof(val, Exception)
			throw val->string()
		endif

		return val
	enddef # }}}
endclass # }}}

export class AsyncIO extends Async # {{{1
	static def Run(co: Coroutine) # {{{2
		timer_start(co.delay, (_) => {
			co.Func()
		})
	enddef # }}}

	static def Gather(...cos: list<Coroutine>): Coroutine # {{{2
		for co in cos:
				AsyncIO.Run(co)
		endfor

		return Coroutine.new((cs: list<Coroutine>): list<any> => {
			return cs->mapnew((_, co) => this.Await<any>(co))->filter((_, v) => !instanceof(v, Void))
		}, cos)
	enddef
endclass # }}}
