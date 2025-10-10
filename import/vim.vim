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

export const void = SingleVoid.new()
final coroutine = IncID.new()

export class Ring # {{{1
	var _list: list<any>
	var _i: number

	def new(a: any = null) # {{{2
		this._list = a == null ? [] : [a]
	enddef # }}}

	def len(): number # {{{2
		return len(this._list)
	enddef # }}}

	def empty(): bool # {{{2
		return this->len() == 0
	enddef # }}}

	def SwitchOf(F: func(any): bool) # {{{2
		if this->empty()
			return
		endif

		var maxCount = this->len()
		var count: number
		var i = this._i
		while !F(this.Peek()) && count < maxCount
			this.SlideRight()
			count += 1
		endwhile

		if count >= maxCount
			this._i = i
		endif
	enddef # }}}

	def Peek(): any # {{{2
		if this->empty()
			return null
		endif

		return this._list[this._i]
	enddef # }}}

	def Pop(): any # {{{2
		if this->empty()
			return null
		endif

		var c = remove(this._list, this._i)
		if this->empty()
			this._i = 0
			return c
		endif

		this._i %= this->len()

		return c
	enddef # }}}

	def Push(t: any) # {{{2
		if this->empty()
			add(this._list, t)
		else
			insert(this._list, t, (this._i + 1))
		endif
		this._i = (this._i + 1) % this->len()
	enddef # }}}

	def SlideLeft() # {{{2
		this._i = (this._i - 1 + this->len()) % this->len()
	enddef # }}}

	def SlideRight() # {{{2
		this._i = (this._i + 1) % this->len()
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

export class List # {{{1
	var head: any
	var tail: List

	def new(this.head, this.tail) # {{{2
	enddef # }}}

	def len(): number # {{{2
		var count = 1
		var tail = this.tail
		while tail != null_object
			count += 1
			tail = this.tail
		endwhile

		return count
	enddef # }}}

	def string(): string # {{{2
		var str = []
		var l = this
		while l != null_object
			str->add(l.head)
			l = l.tail
		endwhile

		return str->string()
	enddef # }}}

	static def Append(list: List, a: any): List # {{{2
		if list == null_object
			return List.new(a, null_object)
		endif

		var l = list
		while l.tail != null_object
			l = l.tail
		endwhile

		l.tail = List.new(a, null_object)
		return list
	enddef # }}}
endclass # }}}

export class Zipper # {{{1
	var _left: List
	var _right: List

	def Peek(): any # {{{2
		if this._right == null_object
			return null
		endif

		return this._right.head
	enddef # }}}

	def Push(a: any) # {{{2
		this._right = List.Append(this._right, a)
	enddef # }}}

	def Pop(): any # {{{2
		if this._right == null_object && this._left == null_object
			return null
		endif

		if this._right == null_object
			var head = this._left.head
			this._left = this.left.tail
			return head
		endif

		var head = this._right.head
		this._right = this._right.tail
		return head
	enddef # }}}

	def Left() # {{{2
		if this._right == null_object
			return
		endif

		var [right, tail] = (this._right.head, this._right.tail)
		this._right = tail
		this._left = List.new(right, this._left)
	enddef # }}}

	def Right() # {{{2
		if this._left == null_object
			return
		endif

		var [left, tail] = (this._left.head, this._left.tail)
		this._left = tail
		this._right = List.new(left, this._right)
	enddef # }}}
endclass # }}}

export class IncID # {{{1
	var _id = -1

	def ID(): number # {{{2
		this._id += 1
		return this._id
	enddef # }}}

	def Peek(): number # {{{2
		return this._id
	enddef # }}}
endclass # }}}

export class Exception # {{{1
	var _exception: string

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
				this._ret[this.id] = Exception.new(substitute(v:exception, '^Vim.*:', '', ''))
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

class InternalAsyncIO extends Async # {{{1
	def Run(co: Coroutine) # {{{2
		timer_start(co.delay, (_) => {
			call(co.Func, [])
		})
	enddef # }}}

	def Gather(...cos: list<Coroutine>): Coroutine # {{{2
		for co in cos:
				AsyncIO.Run(co)
		endfor

		return Coroutine.new((cs: list<Coroutine>): list<any> => {
			return cs->mapnew((_, co) => this.Await<any>(co))->filter((_, v) => !instanceof(v, Void))
		}, cos)
	enddef # }}}
endclass # }}}

export const AsyncIO = InternalAsyncIO.new()

export def AnyRegexp(regexps: list<string>, text: string, ignorecase: bool = false): bool # {{{1
	def Case(regexp: string, str: string): bool # {{{2
		return !ignorecase ? str =~# regexp : str =~ regexp
	enddef # }}}

	for regexp in regexps
		if Case(regexp, text)
			return true
		endif
	endfor

	return false
enddef # }}}

export def AllRegexp(regexps: list<string>, text: string, ignorecase: bool = false): bool # {{{1
	def Case(regexp: string, str: string): bool # {{{2
		return !ignorecase ? str =~# regexp : str =~ regexp
	enddef # }}}

	for regexp in regexps
		if !Case(regexp, text)
			return false
		endif
	endfor

	return true
enddef # }}}
