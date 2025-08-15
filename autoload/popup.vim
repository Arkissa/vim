vim9script

export class PopupWindow
	var winnr: number
	var win_options: dict<any>
	var on_set_buf_pre: list<func(number, number)>
	var on_set_buf_after: list<func(number, number)>
	var on_close: list<func(number, any)>

	def new(options: dict<any>, bufnr: number = 0)
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", "off")
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmenthod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef

	def SetVar(name: string, value: any)
		setwinvar(this.winnr, name, value)
	enddef

	def SetBuf(bufnr: number): bool
		for f in this.on_set_buf_pre
			f(this.winnr, bufnr)
		endfor

		var ok = popup_setbuf(this.winnr, bufnr)
		if !ok
			return false
		endif

		for f in this.on_set_buf_pre
			f(this.winnr, bufnr)
		endfor

		return true
	enddef

	def SetTitle(title: string)
		this.win_options.title = title
		popup_setoptions(this.winnr, this.win_options)
	enddef

	def SetCursor(lnum: number, col: number)
		this.Execute($"eval cursor({lnum}, {col})")
	enddef

	def GetWinnr(): number
		return this.winnr
	enddef

	def GetVar(name: string): any
		return getwinvar(this.winnr, name)
	enddef

	def OnSetBufPre(...f: list<func(number, number)>)
		this.on_set_buf_pre->extend(f)
	enddef

	def OnSetBufAfter(...f: list<func(number, number)>)
		this.on_set_buf_after->extend(f)
	enddef

	def OnClose(...f: list<func(number, any)>)
		this.on_close->extend(f)
	enddef

	def _CloseCallback(id: number, result: any)
		for f in this.on_close_pre
			f(id, result)
		endfor

		this.winnr = -1
	enddef

	def IsOpen(): bool
		return this.winnr != -1
	enddef

	def Close(result: any = v:none)
		if result is v:none
			result = winbufnr(this.winnr)
		endif

		this.winnr->popup_close(result)
	enddef

	def Execute(...cmds: list<string>)
		for cmd in cmds
			this.winnr->win_execute(cmd)
		endfor
	enddef

	def FeedKeys(keys: string, mode: string = v:none)
		var cmd = [keys]
		if mode is v:none
			cmd->add(mode)
		endif

		this.winnr->win_execute($"vim9 feedkeys({cmd->join(', ')})")
	enddef
endclass
