vim9script

export enum Mods
	n,
	v,
	i,
	x,
	s,
	o,
	ic,
	l,
	c,
	t
endenum

export class Bind
	var _mods: list<Mods> = []
	var _cmd = 'map'
	var _args: list<string> = []
	var _lhies: list<string> = []
	var _rhies: list<string> = []
	var _tails: list<string> = []
	var _noremap: bool
	var _MapBy: func(): bool

	def new(m: Mods)
		this._mods->add(m)
	enddef

	def newMulti(...ms: list<Mods>)
		this._mods->extend(ms)
	enddef

	def LHS(lhs: string): Bind
		this._lhies->add(lhs)
		return this
	enddef

	def RHS(rhs: string): Bind
		this._rhies->add(rhs)
		return this
	enddef

	def Buffer(): Bind
		this._args->add('<buffer>')
		return this
	enddef

	def NoWait(): Bind
		this._args->add('<nowait>')
		return this
	enddef

	def Silent(): Bind
		this._args->add('<silent>')
		return this
	enddef

	def Special(): Bind
		this._args->add('<special>')
		return this
	enddef

	def Script(): Bind
		this._args->add('<script>')
		return this
	enddef

	def Expr(): Bind
		this._args->add('<expr>')
		return this
	enddef

	def Unique(): Bind
		this._args->add('<unique>')
		return this
	enddef

	def NoRemap(): Bind
		this._noremap = true
		return this
	enddef

	def By(F: func(): bool): Bind
		this._MapBy = funcref(F)
		return this
	enddef

	def Done()
		if len(this._lhies) != len(this._rhies)
			throw "keymap bind the lens of lhs and rhs is not equal."
		endif

		if !call(this._MapBy, [])
			return
		endif

		var args = join(this._args, ' ')
		for i in range(len(this._lhies))
			add(this._tails, $'{args} {this._lhies[i]} {this._rhies[i]}')
		endfor

		var cmd = this._noremap ? $'nore{this._cmd}' : this._cmd
		var m: string
		for mod in this._mods
			if mod.name != 'ic'
				m = $'{mod.name}{cmd}'
			else
				m = $'{cmd}!'
			endif

			for tail in this._tails
				execute($'{m} {tail}')
			endfor
		endfor
	enddef
endclass
