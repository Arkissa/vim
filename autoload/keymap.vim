vim9script

export enum Mods # {{{1
	n, # {{{2
	v, # {{{2
	i, # {{{2
	x, # {{{2
	s, # {{{2
	o, # {{{2
	ic, # {{{2
	l, # {{{2
	c, # {{{2
	t # {{{2
endenum

export class Bind # {{{1
	const _cmd = 'map'
	var _mods: list<Mods> = []
	var _args: list<string> = []
	var _arg: string
	var _noremap: bool
	var _When: func(): bool
	static var _mapFunction: dict<func()> = {} # {{{2

	static def InternalFunction(name: string): func() # {{{2
		return _mapFunction[name]
	enddef

	def new(m: Mods) # {{{2
		this._mods->add(m)
	enddef

	def newMulti(...ms: list<Mods>) # {{{2
		this._mods->extend(ms)
	enddef

	def ScriptCmd(lhs: string, Rhs: func()): Bind # {{{2
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

	def Map(lhs: string, rhs: string): Bind # {{{2
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

	def Buffer(): Bind # {{{2
		this._args->add('<buffer>')
		return this
	enddef

	def NoWait(): Bind # {{{2
		this._args->add('<nowait>')
		return this
	enddef

	def Silent(): Bind # {{{2
		this._args->add('<silent>')
		return this
	enddef

	def Special(): Bind # {{{2
		this._args->add('<special>')
		return this
	enddef

	def Script(): Bind # {{{2
		this._args->add('<script>')
		return this
	enddef

	def Expr(): Bind # {{{2
		this._args->add('<expr>')
		return this
	enddef

	def Unique(): Bind # {{{2
		this._args->add('<unique>')
		return this
	enddef

	def NoRemap(): Bind # {{{2
		this._noremap = true
		return this
	enddef

	def When(F: func(): bool): Bind # {{{2
		this._When = F
		return this
	enddef
endclass
