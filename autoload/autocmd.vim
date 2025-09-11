vim9script

export class Autocmd
	var _group: string # {{{2

	var _when: func(): bool # {{{2

	var _autocmd: dict<any> = { # {{{2
		pattern: '*'
	}

	static var _enviroment: dict<func()> = {} # {{{2

	def new(event: string) # {{{2
		this._autocmd.event = event
	enddef

	def newMulti(events: list<string>) # {{{2
		this._autocmd.event = events
	enddef

	static def InternalFunction(id: number): func() # {{{2
		return _enviroment[id]
	enddef

	def When(F: func(): bool): Autocmd # {{{2
		this._when = F
		return this
	enddef

	def Group(group: string): Autocmd # {{{2
		this._autocmd.group = group
		return this
	enddef

	def Pattern(patterns: list<string>): Autocmd # {{{2
		this._autocmd.pattern = patterns
		return this
	enddef

	def Nested(): Autocmd # {{{2
		this._autocmd.nested = true
		return this
	enddef

	def Once(): Autocmd # {{{2
		this._autocmd.once = true
		return this
	enddef

	def Bufnr(bufnr: number): Autocmd # {{{2
		this._autocmd.bufnr = bufnr
		return this
	enddef

	def Replace(): Autocmd # {{{2
		this._autocmd.replace = true
		return this
	enddef

	def Command(cmd: string): Autocmd # {{{2
		if this._when != null_function && !call(this._when, [])
			return this
		endif

		this._autocmd.cmd = cmd
		autocmd_add([this._autocmd])
		return this
	enddef

	def Callback(F: func()): Autocmd # {{{2
		if this._when != null_function && !call(this._when, [])
			return this
		endif

		var id = rand()
		_enviroment[id] = F

		this._autocmd.cmd = $'call(Autocmd.InternalFunction({id}), [])'
		autocmd_add([this._autocmd])
		return this
	enddef # }}}
endclass
