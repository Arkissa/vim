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

export class Exception # {{{1
	var _exception: string # {{{2
	def new(this._exception) # {{{2
	enddef # }}}

	def string(): string # {{{2
		return this._exception
	enddef # }}}
endclass # }}}

export class TimeoutException extends Exception
	def new(s: string)
		this._exception = $'Timeout: ${s}'
	enddef
endclass

export class Ring # {{{1
	var _list: list<any>
	var _i: number

	def new(a: any)
		this._list = [a]
	enddef

	def len(): number
		if this == null_object
			return 0
		endif

		return len(this._list)
	enddef

	def empty(): bool
		return this->len() == 0
	enddef

	def Current<T>(): T
		return this._list[this._i]
	enddef

	def Remove<T>(): T
		if this->empty()
			return null_object
		endif

		var c = remove(this._list, this._i)
		if this->empty()
			return c
		endif

		this._i %= this->len()

		return c
	enddef

	def Add<T>(t: T)
		insert(this._list, t, this._i + 1)
		this._i = (this._i + 1) % this->len()
	enddef

	def SlideLeft(): Ring
		this._i = (this._i - 1) % this->len()
		return this
	enddef

	def SlideRight(): Ring
		this._i = (this._i + 1) % this->len()
		return this
	enddef

	def ToList<T>(): list<T>
		return copy(this._list)
	enddef

	def ForEach(F: func(any))
		for item in this._list
			F(item)
		endfor
	enddef
endclass # }}}

export class Coroutine
	var id: number
	var Func: func
	var args: list<any>

	def new(this.Func, ...args: list<any>)
		this.id = rand()

		this.args = args
	enddef
endclass

export class AsyncIO
	static var _returns = {}

	static def Gather(...asyncs: list<Coroutine>): Coroutine
		for a in as.items():
			Coroutine.Run(a)
		endfor

		return Coroutine.new((as: list<Coroutine>): list<any> => {
			var results = []

			for a in as:
				results->add(AsyncIO.Await<any>(a))
			endfor

			return results
		}, asyncs)
	enddef

	static def Await<T>(co: Coroutine, time: number = 0): T
		var timer = -1
		var returns = _returns

		if time > 0
			timer = timer_start(time, (_) => {
				returns[co.id] = TimeoutException.new($'wait for {co.id} coroutine return values timeout.')
			})
		endif

		while !has_key(returns, co.id)
			:sleep 50m
		endwhile
		timer_stop(timer)

		var val = returns[aysnc.id]
		if type(val) == type(null_object) && instanceof(val, Exception)
			throw val->string()
		endif

		return val
	enddef

	static def Run(co: Coroutine, time: number = 0)
		var returns = _returns

		timer_start(time, (_) => {
			try
				var val = call(co.Func, co.args)
				returns[co.id] = val
			catch /E1186\|E1031/
				returns[co.id] = void
			catch
				returns[co.id] = Exception.new(v:exception)
			endtry
		})
	enddef
endclass
