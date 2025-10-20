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
		if !this->empty()
			this._i = (this._i - 1 + this->len()) % this->len()
		endif
	enddef # }}}

	def SlideRight() # {{{2
		if !this->empty()
			this._i = (this._i + 1) % this->len()
		endif
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

export type TupleList = tuple<...list<any>>

export class List # {{{1
	static def Head(list: TupleList): any # {{{2
		if list->empty()
			throw 'empty list'
		endif

		return list[0]
	enddef # }}}

	static def Tail(list: TupleList): TupleList # {{{2
		if list->empty()
			throw 'empty list'
		endif

		if list->len() == 1
			return ()
		endif

		return list->len() == 2 && type(list[1]) == v:t_tuple
			? list[1]
			: list[1 : ]
	enddef # }}}

	static def Foldl(F: func(any, any): any, init: any, list: TupleList): any # {{{2
		var i = init
		var l = list

		while !l->empty()
			i = F(Head(l), i)
			l = Tail(l)
		endwhile

		return i
	enddef # }}}

	static def Foldr(F: func(any, any): any, init: any, list: TupleList): any # {{{2
		if list->empty()
			return init
		endif

		return Foldr(F, F(Head(list), init), Tail(list))
	enddef # }}}

	static def Reverse(p: TupleList): TupleList # {{{2
		return Foldl((a, b) => (a, b), (), p)
	enddef # }}}

	static def Concat(l1: TupleList, l2: TupleList): TupleList # {{{2
		return Foldl((a, b) => (a, b), l2, Reverse(l1))
	enddef # }}}

	static def Append(list: TupleList, a: any): TupleList # {{{2
		return Concat(list, (a,))
	enddef # }}}

	static def Map(F: func(any): any, list: TupleList): TupleList # {{{2
		return Foldl((a, b) => (F(a), b), (), Reverse(list))
	enddef # }}}

	static def Filter(F: func(any): bool, list: TupleList): TupleList # {{{2
		var l = list

		var new = ()
		while !l->empty()
			if F(Head(l))
				new = (Head(l), new)
			endif

			l = Tail(l)
		endwhile

		return Reverse(new)
	enddef # }}}

	static def Show(list: TupleList): string # {{{2
		if list->empty()
			return ''
		endif

		var buf = []
		var l = list
		while !l->empty()
			var h = Head(l)

			buf->add(type(h) == v:t_tuple
				? Show(h)
				: h->string())

			l = Tail(l)
		endwhile

		return $'({buf->join(', ')})'
	enddef # }}}

	static def ToVimList(list: TupleList): list<any> # {{{2
		if list->empty()
			return []
		endif

		var buf = []
		var l = list
		while !l->empty()
			buf->add(Head(l))
			l = Tail(l)
		endwhile

		return buf
	enddef # }}}

	static def FromVimList(list: list<any>): TupleList # {{{2
		return list->list2tuple()
	enddef # }}}
endclass # }}}

export class Zipper # {{{1
	var _left: TupleList = ()
	var _right: TupleList = ()

	def Peek(): any # {{{2
		if this._right->empty()
			return null
		endif

		return List.Head(this._right)
	enddef # }}}

	def Push(a: any) # {{{2
		this._right = List.Append(this._right, a)
	enddef # }}}

	def Pop(): any # {{{2
		if this._right->empty()
			var head = List.Head(this._left)
			this._left = List.Tail(this.left)
			return head
		endif

		if this._left->empty()
			var head = List.Head(this._right)
			this._right = List.Tail(this.right)
			return head
		endif

		return null
	enddef # }}}

	def Left() # {{{2
		if this._left->empty()
			return
		endif

		var [left, tail] = (List.Head(this._left), List.Tail(this._left))
		this._left = tail
		this._right = (left, this._right)
	enddef # }}}

	def Right() # {{{2
		if this._right->empty()
			return
		endif

		var [right, tail] = (List.Head(this._right), List.Tail(this._right))
		this._right = tail
		this._left = (right, this._left)
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

final coroutine = IncID.new()

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
		if type(val) == v:t_object && instanceof(val, Exception)
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
