vim9script

export class Window
	var winnr: number = -1
	var _on_set_buf_pre: list<func(Window)>
	var _on_set_buf_after: list<func(Window)>
	var _on_close: list<func(Window, any)>
	var _hidden: bool = false

	def new(bufnr: number, options: dict<any>)
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", 0)
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmethod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef

	def SetVar(name: string, value: any)
		setwinvar(this.winnr, name, value)
	enddef

	def SetFilter(F: func(Window, string): bool)
		this.SetOptions({
			filter: (_: number, key: string) => F(this, key)
		})
	enddef

	def SetOptions(options: dict<any>)
		popup_setoptions(this.winnr, options)
	enddef

	def SetBuf(bufnr: number): bool
		for F in this._on_set_buf_pre
			F(this)
		endfor

		var ok = popup_setbuf(this.winnr, bufnr)
		if !ok
			return false
		endif

		for F in this._on_set_buf_after
			F(this)
		endfor

		return true
	enddef

	def SetTitle(title: string)
		this.SetOptions({title: title})
	enddef

	def SetCursor(lnum: number, col: number)
		this.Execute($"eval cursor({lnum}, {col})")
	enddef

	def GetBufnr(): number
		return winbufnr(this.winnr)
	enddef

	def GetVar(name: string): any
		return getwinvar(this.winnr, name)
	enddef

	def GetOptions()
		return popup_getoptions(this.winnr)
	enddef

	def OnSetBufPre(...f: list<func(Window)>)
		extend(this._on_set_buf_pre, f)
	enddef

	def OnSetBufAfter(...f: list<func(Window)>)
		extend(this._on_set_buf_after, f)
	enddef

	def OnClose(...f: list<func(Window, any)>)
		extend(this._on_close, f)
	enddef

	def _CloseCallback(id: number, result: any)
		for F in this._on_close
			F(this, result)
		endfor

		this.winnr = -1
	enddef

	def IsOpen(): bool
		return this.winnr != -1
	enddef

	def IsHidden(): bool
		return this.IsOpen() && this.hidden
	enddef

	def Close(result: any = null)
		var r = result
		if r == null
			r = winbufnr(this.winnr)
		endif

		popup_close(this.winnr, r)
		this.winnr = -1
	enddef

	def Execute(...cmds: list<string>)
		for cmd in cmds
			win_execute(this.winnr, cmd)
		endfor
	enddef

	def FeedKeys(keys: string, mode: string = "m")
		var cmd = [keys]

		this.Execute($"call feedkeys('{keys}', '{mode}')")
	enddef

	def Hide()
		popup_hide(this.winnr)
		this._hidden = true
	enddef

	def Show(): number
		popup_show(this.winnr)
		this._hidden = false
	enddef
endclass
