vim9script

export abstract class Pair
	def empty(): bool
		return instanceof(this, Nil)
	enddef

	def len(): number
		var p: any = this
		var count = 0

		while !p->empty()
			count += 1
			p = p.cdr
		endwhile

		return count
	enddef

	def string(): string
		if this->empty()
			return ''
		endif

		var buffer = []
		var p: any = this

		while !p->empty()
			buffer->add(p.car)
			p = p.cdr
		endwhile

		return $'({buffer->join(', ')})'
	enddef
endclass

class Nil extends Pair
endclass

export const nil = Nil.new()

class Cons_ extends Pair
	var car: any
	var cdr: Pair

	def new(this.car, this.cdr)
	enddef
endclass

export def Cons(a: any, p: Pair = nil): Pair
	return Cons_.new(a, p)
enddef

export def Foldl<A, B>(F: func(A, B): B, init: B, pair: Pair): B
	var i = init
	var p: any = pair

	while !p->empty()
		i = F(p.car, i)
		p = p.cdr
	endwhile

	return i
enddef

export def Foldr<A, B>(F: func(A, B): B, init: B, pair: Pair): B
	if pair->empty()
		return init
	endif

	var p: any = pair
	return Foldr<A, B>(F, F(p.car, init), p.cdr)
enddef

export def Reverse(p: Pair): Pair
	return Foldl<any, Pair>(Cons, nil, p)
enddef

export def Concat(p1: Pair, p2: Pair): Pair
	return Foldl<any, Pair>(Cons, p2, Reverse(p1))
enddef

export def Filter<A>(F: func(A): bool, pair: Pair): Pair
	var p: any = pair

	var new: Pair = nil
	while !p->empty()
		if F(p.car)
			new = Cons(p.car, new)
		endif

		p = p.cdr
	endwhile

	return Reverse(new)
enddef

export def Map<A, B>(F: func(A): B, pair: Pair): Pair
	return Foldl<A, Pair>((a: A, b: Pair) => Cons(a, b), nil, Reverse(pair))
enddef

export def Car(a: Pair): any
	if a->empty()
		throw 'empty list'
	endif

	var p: any = a
	return p.car
enddef

export def Cdr(a: Pair): any
	if a->empty()
		throw 'empty list'
	endif

	var p: any = a
	return p.cdr
enddef

export def Append(p: Pair, a: any): Pair
	return Concat(p, Cons(a))
enddef

export def FromList(as: list<any>): Pair
	var p: Pair = nil
	for i in range(len(as) - 1, 0, -1)
		p = Cons(as[i], p)
	endfor

	return p
enddef

export def ToList(as: Pair): list<any>
	var a = []
	var p: any = as
	while !p->empty()
		a->add(Car(p))
		p = Cdr(p)
	endwhile

	return a
enddef
