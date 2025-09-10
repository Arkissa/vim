vim9script

export class Autocmd
	var _autocmd: dict<any> = {
		pattern: '*'
	}
	var _group: string
	var _when: func(): bool
	static var _enviroment: dict<func()> = {}

	def new(event: string)
		this._autocmd.event = event
	enddef

	def newMulti(events: list<string>)
		this._autocmd.event = events
	enddef

	static def InternalFunction(id: number): func()
		return _enviroment[id]
	enddef

	def When(F: func(): bool): Autocmd
		this._when = F
		return this
	enddef

	def Group(group: string): Autocmd
		this._autocmd.group = group
		return this
	enddef

	def Pattern(patterns: list<string>): Autocmd
		this._autocmd.pattern = patterns
		return this
	enddef

	def Nested(): Autocmd
		this._autocmd.nested = true
		return this
	enddef

	def Once(): Autocmd
		this._autocmd.once = true
		return this
	enddef

	def Bufnr(bufnr: number): Autocmd
		this._autocmd.bufnr = bufnr
		return this
	enddef

	def Replace(): Autocmd
		this._autocmd.replace = true
		return this
	enddef

	def Command(cmd: string): Autocmd
		if this._when != null_function && !call(this._when, [])
			return this
		endif

		this._autocmd.cmd = cmd
		autocmd_add([this._autocmd])
		return this
	enddef

	def Callback(F: func()): Autocmd
		if this._when != null_function && !call(this._when, [])
			return this
		endif

		var id = rand()
		_enviroment[id] = F

		this._autocmd.cmd = $'call(Autocmd.InternalFunction({id}), [])'
		autocmd_add([this._autocmd])
		return this
	enddef
endclass
