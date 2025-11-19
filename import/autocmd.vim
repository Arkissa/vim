vim9script

export class EventArgs
	var id: number
	var buf: number
	var data: any
	var event: string
	var group: string
	var match: string

	def new(this.id, this.buf, this.event, this.group, this.match, data: any = null)
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

	def new(this._F, this.event, this.group)
		this.id = id(this)->str2nr(16)
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
					bufnr(),
					this.event,
					this.group,
					expand('<amatch>'),
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
	var desc: string

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

	static def InternalFunction(id: number, once: bool): Callback
		return once ? remove(_enviroment, id) : _enviroment[id]
	enddef

	static def Get(opts: dict<any> = null_dict): list<dict<any>>
		if opts == null_dict
			return autocmd_get()
		endif

		try
			return autocmd_get(opts)
		catch /E367/
		endtry

		return []
	enddef

	static def Do(group: string, event: string, pattern: string, data: any = null)
		_enviroment
			->copy()
			->filter((_, c) => c.event =~# event)
			->foreach((_, c) => {
				c.SetData(data)
			})

		execute(['doautocmd', '<nomodeline>', group, event, pattern]->join())
	enddef

	static def Delete(opts: list<dict<any>>, deleteFunction: bool = true)
		if deleteFunction
			var to_delete = []

			for opt in opts
				to_delete->extend(Autocmd.Get(opt))
			endfor

			if to_delete->empty()
				return
			endif

			var ids = to_delete
				->mapnew((_, au) => matchstr(au.cmd, 'InternalFunction(\zs\d\+\ze, \(true\|false\))'))
				->filter((_, id) => id != '')
				->mapnew((_, id) => str2nr(id))

			for id in ids
				if has_key(_enviroment, id)
					remove(_enviroment, id)
				endif
			endfor
		endif

		autocmd_delete(opts)
	enddef

	def When(F: func(): bool): Autocmd
		this._when = F
		return this
	enddef

	def Desc(desc: string): Autocmd
		this.desc = $' # {desc}'
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

	def Bufnr(bufnr: number = bufnr()): Autocmd
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

		this._autocmd.cmd = cmd .. this.desc
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

		var autocmds = [this._autocmd.event]->flattennew()->mapnew((_, event) => {
			var callback = Callback.new(F, event, group)
			enviroment[callback.id] = callback
			var autocmd = {
				event: event,
				cmd: $'Autocmd.InternalFunction({callback.id}, {get(this._autocmd, 'once', false)}).Call(){this.desc}'}

			return extend(autocmd, this._autocmd, 'keep')
		})
		autocmd_add(autocmds)
		return this
	enddef
endclass
