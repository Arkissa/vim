vim9script

export class Window
	var winnr: number = -1
	var _on_set_buf_pre: list<func(number, number)>
	var _on_set_buf_after: list<func(number, number)>
	var _on_close: list<func(number, any)>
	var _hidden: bool = false

	def new(options: dict<any>, bufnr: number = 0)
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", "off")
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmenthod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef

	def SetVar(name: string, value: any)
		this.winnr->setwinvar(name, value)
	enddef

	def SetOptions(options: dict<any>)
		this.winnr->popup_setoptions(options)
	enddef

	def SetBuf(bufnr: number): bool
		for f in this._on_set_buf_pre
			f(this.winnr, bufnr)
		endfor

		var ok = this.winnr->popup_setbuf(bufnr)
		if !ok
			return false
		endif

		for f in this.on_set_buf_pre
			f(this.winnr, bufnr)
		endfor

		return true
	enddef

	def SetTitle(title: string)
		this.SetOptions({title: title})
	enddef

	def SetCursor(lnum: number, col: number)
		this.Execute($"cursor({lnum}, {col})")
	enddef

	def GetVar(name: string): any
		return this.winnr->getwinvar(name)
	enddef

	def GetOptions()
		return this.winnr->popup_getoptions()
	enddef

	def OnSetBufPre(...f: list<func(number, number)>)
		this._on_set_buf_pre->extend(f)
	enddef

	def OnSetBufAfter(...f: list<func(number, number)>)
		this._on_set_buf_after->extend(f)
	enddef

	def OnClose(...f: list<func(number, any)>)
		this._on_close->extend(f)
	enddef

	def _CloseCallback(id: number, result: any)
		for f in this._on_close_pre
			f(id, result)
		endfor

		this.winnr = -1
	enddef

	def IsOpen(): bool
		return this.winnr != -1
	enddef

	def IsHidden(): bool
		return this.IsOpen() && this.hidden
	enddef

	def Close(result: any = v:none)
		if result is v:none
			result = winbufnr(this.winnr)
		endif

		this.winnr->popup_close(result)
		this.winnr = -1
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

	def Hide()
		this.winnr->popup_hide()
		this._hidden = true
	enddef

	def Show(): number
		this.winnr->popup_show()
		this._hidden = false
	enddef
endclass
