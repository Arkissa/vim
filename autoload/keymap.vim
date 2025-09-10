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
	var _arg: string
	var _noremap: bool
	var _When: func(): bool
	static var _mapFunction: dict<func()> = {}

	static def InternalFunction(name: string): func()
		return _mapFunction[name]
	enddef

	def new(m: Mods)
		this._mods->add(m)
	enddef

	def newMulti(...ms: list<Mods>)
		this._mods->extend(ms)
	enddef

	def ScriptCmd(lhs: string, Rhs: func()): Bind
		if this._When != null_function && !call(this._When, [])
			return this
		endif

		if this._arg == null_string
			this._arg = this._args->join(' ')
		endif

		var cmd = this._noremap ? $'nore{this._cmd}' : this._cmd
		var m: string
		for mod in this._mods
			if mod.name != 'ic'
				m = $'{mod.name}{cmd}'
			else
				m = $'{cmd}!'
			endif

			var name = $'{m}_{rand()}'
			_mapFunction[name] = Rhs

			execute($'{m} {this._arg} {lhs} <ScriptCmd>call(Bind.InternalFunction("{name}"), [])<CR>')
		endfor

		return this
	enddef

	def Map(lhs: string, rhs: string): Bind
		if this._When != null_function && !call(this._When, [])
			return this
		endif

		if this._arg == null_string
			this._arg = this._args->join(' ')
		endif

		var cmd = this._noremap ? $'nore{this._cmd}' : this._cmd
		var m: string
		for mod in this._mods
			if mod.name != 'ic'
				m = $'{mod.name}{cmd}'
			else
				m = $'{cmd}!'
			endif

			execute($'{m} {this._arg} {lhs} {rhs}')
		endfor

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

	def When(F: func(): bool): Bind
		this._When = funcref(F)
		return this
	enddef
endclass
