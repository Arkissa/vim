vim9script

export def Cmd(s: list<string>): string # {{{1
	return s->join(' ')
enddef # }}}

export def Option(s: list<string>): string # {{{1
	return s->join(',')
enddef # }}}

export type TupleList = tuple<...list<any>>

export class List # {{{1
	static def Head(list: TupleList): any # {{{2
		if list->empty()
			throw 'empty list'
		endif

		return list[0]
	enddef # }}}

	static def Length(a: TupleList): number # {{{2
		return Foldl((_, count) => count + 1, 0, a)
	enddef # }}}

	static def Tail(list: TupleList): TupleList # {{{2
		if list->empty()
			throw 'empty list'
		endif

		if list->len() > 2
			return list[1 : ]
		endif

		return list->len() == 2 && type(list[1]) == v:t_tuple
			? list[1]
			: list[1 : ]
	enddef # }}}

	static def DeleteBy(F: func(any, any): bool, x: any, xs: TupleList): TupleList # {{{2
		if xs->empty()
			return ()
		endif

		var new = ()
		var old = xs
		while !old->empty()
			var a = List.Head(old)
			if F(x, a)
				return List.Concat(List.Reverse(new), List.Tail(old))
			endif

			new = (a, new)
			old = List.Tail(old)
		endwhile

		return xs
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

export class Ring # {{{1
	var _right: TupleList = null_tuple
	var _left: TupleList = null_tuple

	def new(a: TupleList = null_tuple) # {{{2
		this._right = a
	enddef # }}}

	def len(): number # {{{2
		return List.Length(this._right) + List.Length(this._left)
	enddef # }}}

	def empty(): bool # {{{2
		return this._left->empty() && this._right->empty()
	enddef # }}}

	def SwitchOf(F: func(any): bool) # {{{2
		if this->empty()
			return
		endif
		var saved_right = this._right
		var saved_left = this._left
		var found = false

		defer () => {
			if !found
				this._left = saved_left
				this._right = saved_right
			endif
		}()

		var maxCount = this->len()
		var count = 0

		while count < maxCount
			if this._right->empty()
				[this._right, this._left] = (List.Reverse(this._left), null_tuple)
			endif

			if F(List.Head(this._right))
				found = true
				return
			endif

			this.SlideRight()
			count += 1
		endwhile
	enddef # }}}

	def Peek(): any # {{{2
		if this->empty()
			return null
		endif

		if this._right->empty()
			[this._right, this._left] = (List.Reverse(this._left), null_tuple)
		endif

		return List.Head(this._right)
	enddef # }}}

	def Pop(): any # {{{2
		if this->empty()
			return null
		endif

		if this._right->empty()
			[this._right, this._left] = (List.Reverse(this._left), null_tuple)
		endif

		var a = List.Head(this._right)
		this._right = List.Tail(this._right)
		return a
	enddef # }}}

	def Push(a: any) # {{{2
		this._right = (a, this._right)
	enddef # }}}

	def SlideLeft() # {{{2
		if this->empty()
			return
		endif

		if this._left->empty()
			[this._left, this._right] = (List.Reverse(this._right), null_tuple)
		endif

		this._right = (List.Head(this._left), this._right)
		this._left = List.Tail(this._left)
	enddef # }}}

	def SlideRight() # {{{2
		if this->empty()
			return
		endif

		if this._right->empty()
			[this._right, this._left] = (List.Reverse(this._left), null_tuple)
		endif

		this._left = (List.Head(this._right), this._left)
		this._right = List.Tail(this._right)
	enddef # }}}

	def ToList<T>(): list<T> # {{{2
		return List.ToVimList(List.Reverse(this._left)) + List.ToVimList(this._right)
	enddef # }}}

	def ForEach(F: func(any)) # {{{2
		for item in this.ToList<any>()
			F(item)
		endfor
	enddef # }}}

	def DeleteBy(F: func(any, any): bool, a: any) # {{{2
		var xs = List.DeleteBy(F, a, this._right)
		if List.Length(xs) != List.Length(this._right)
			this._right = xs

			if this._right->empty() && !this._left->empty()
				[this._right, this._left] = (List.Reverse(this._left), null_tuple)
			endif
			return
		endif

		this._left = List.DeleteBy(F, a, this._left)
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

export def Contains(s: any, e: any, start: number = 0, ic: bool = false): bool # {{{1
	return index((v:t_list, v:t_tuple, v:t_blob), type(s)) >= 0 && index(s, e, start, ic) >= 0
enddef # }}}

export def ContainsOf(s: any, F: func(any, any): bool, opts: dict<any> = {startidx: 0}): bool # {{{1
	return index((v:t_list, v:t_tuple, v:t_blob), type(s)) >= 0 && indexof(s, F, opts) >= 0
enddef # }}}

export def FindMarks(start: string = '', marks: list<string> = []): tuple<string, string> # {{{2
	var curdir = start ==# ''
		? getcwd()
		: fnamemodify(start, ':p')

	if !isdirectory(curdir)
		curdir = fnamemodify(curdir, ':h')
	endif

	while true
		for mark in marks
			var fs = globpath(curdir, mark, false, true)
			if !fs->empty()
				return (curdir, fs[0])
			endif
		endfor

		if curdir ==# $HOME || curdir ==# '/'
			break
		endif

		curdir = fnamemodify(curdir, ':h')
	endwhile

	return ('', '')
enddef # }}}

export def HasPrefix(s: string, prefix: string): bool # {{{
	return len(s) >= len(prefix) && s[ : len(prefix) - 1] == prefix
enddef # }}}
