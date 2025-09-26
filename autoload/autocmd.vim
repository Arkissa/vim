vim9script

import './buffer.vim'

export class EventArgs
	var id: number
	var buf: buffer.Buffer
	var data: any
	var event: string
	var group: string
	var match: string

	def new(this.id, this.event, this.group, this.match, this.buf, data: any = null)
		this.data = data
	enddef

	def string(): string
		return string({
			id: this.id,
			event: this.event,
			group: this.group,
			match: this.match,
			buf: this.buf,
			data: this.data,
		})
	enddef
endclass

class Callback
	var id: number
	var event: string
	var group: string

	var _F: func
	var _data: any

	def new(this.id, this._F, this.event, this.group)
	enddef

	def SetData(data: any)
		this._data = data
	enddef

	def Call()
		try
			var args = []
			if typename(this._F) != 'func()'
				args->add(EventArgs.new(
					this.id,
					this.event,
					this.group,
					expand('<amatch>'),
					buffer.Buffer.newCurrent(),
					this._data
				))
			endif

			call(this._F, args)
		finally
			this._data = null
		endtry
	enddef
endclass

export class Autocmd
	var _when: func(): bool

	var _autocmd: dict<any> = {
		pattern: '*'
	}

	static var _enviroment: dict<Callback> = {}

	def new(event: string)
		this._autocmd.event = event
	enddef

	def newMulti(events: list<string>)
		this._autocmd.event = events
	enddef

	static def InternalFunction(id: number): Callback
		return _enviroment[id]
	enddef

	static def Do(group: string, event: string, pattern: list<string>, data: any = null)
		_enviroment
			->copy()
			->filter((_, c) => c.event =~# event)
			->foreach((_, c) => {
				c.SetData(data)
			})

		execute(['doautocmd', '<nomodeline>', group, event, pattern->join(',')]->join(' '))
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

	def Callback(F: func): Autocmd
		if ['func()', 'func(any)', 'func(object<EventArgs>)']->index(typename(F)) == -1
			throw 'Autocmd Callback parameter type must be func() or func(any) or func(object<EventArgs>).'
		endif

		if this._when != null_function && !call(this._when, [])
			return this
		endif

		var enviroment = _enviroment
		var group = get(this._autocmd, 'group', '')

		autocmd_add([this._autocmd.event]->flattennew()->mapnew((_, event) => {
			var id = rand()
			enviroment[id] = Callback.new(id, F, event, group)
			var autocmd = {
				event: event,
				cmd: $'Autocmd.InternalFunction({id}).Call()'}

			return extend(autocmd, this._autocmd, 'force')
		}))
		return this
	enddef
endclass
