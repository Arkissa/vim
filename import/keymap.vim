vim9script

import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

export enum Mods # {{{1
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
endenum # }}}

const group = 'KeymapBind'

export class Bind # {{{1
	const _cmd = 'map'

	var _mods: list<Mods> = []
	var _When: func(): bool
	var _noremap: bool
	var _args: dict<string> = {}
	var _bufnr = -1

	static var _mapFunction: dict<func> = {}

	static def InternalFunction(id: number): func # {{{2
		return _mapFunction[id]
	enddef # }}}

	def _Execute(keymap: string) # {{{2
		if this._bufnr == -1
			execute(keymap)
		else
			Autocmd.new('BufEnter')
				.Group(group)
				.Once()
				.Pattern([bufname(this._bufnr)])
				.Callback(() => {
					execute(keymap)
				})
		endif
	enddef # }}}

	def new(m: Mods) # {{{2
		this._mods->add(m)
	enddef # }}}

	def newMulti(...ms: list<Mods>) # {{{2
		this._mods->extend(ms)
	enddef # }}}

	def ScriptCmd(lhs: string, Rhs: func): Bind # {{{2
		if ['func()', 'func(): string', 'func(): any']->index(typename(Rhs)) == -1
			throw 'Rhs type must be func() or func(): string or func(): any.'
		endif
		if this._When != null_function && !call(this._When, [])
			return this
		endif

		var arg = this._args->keys()->join()

		var cmd = this._noremap ? $'nore{this._cmd}' : this._cmd
		var m: string
		for mod in this._mods
			if mod.name != 'ic'
				m = $'{mod.name}{cmd}'
			else
				m = $'{cmd}!'
			endif

			var id = rand()
			_mapFunction[id] = Rhs

			var keymap = arg =~# '<expr>'
				? $'{m} {arg} {lhs} call(Bind.InternalFunction({id}), [])'
				: $'{m} {arg} {lhs} <ScriptCmd>call(Bind.InternalFunction({id}), [])<CR>'

			this._Execute(keymap)
		endfor

		return this
	enddef # }}}

	def Map(lhs: string, rhs: string): Bind # {{{2
		if this._When != null_function && !call(this._When, [])
			return this
		endif

		var arg = this._args->keys()->join()

		var cmd = this._noremap ? $'nore{this._cmd}' : this._cmd
		var m: string
		for mod in this._mods
			if mod.name != 'ic'
				m = $'{mod.name}{cmd}'
			else
				m = $'{cmd}!'
			endif

			this._Execute($'{m} {arg} {lhs} {rhs}')
		endfor

		return this
	enddef # }}}

	def Buffer(bufnr: number = -1): Bind # {{{2
		this._args['<buffer>'] = null_string
		this._bufnr = bufnr
		return this
	enddef # }}}

	def NoWait(): Bind # {{{2
		this._args['<nowait>'] = null_string
		return this
	enddef # }}}

	def Silent(): Bind # {{{2
		this._args['<silent>'] = null_string
		return this
	enddef # }}}

	def Special(): Bind # {{{2
		this._args['<special>'] = null_string
		return this
	enddef # }}}

	def Script(): Bind # {{{2
		this._args['<script>'] = null_string
		return this
	enddef # }}}

	def Expr(): Bind # {{{2
		this._args['<expr>'] = null_string
		return this
	enddef # }}}

	def Unique(): Bind # {{{2
		this._args['<unique>'] = null_string
		return this
	enddef # }}}

	def NoRemap(): Bind # {{{2
		this._noremap = true
		return this
	enddef # }}}

	def When(F: func(): bool): Bind # {{{2
		this._When = F
		return this
	enddef # }}}
endclass # }}}
