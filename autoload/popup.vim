vim9script

import './window.vim'

export class Window extends window.Window # {{{1
	var _hidden: bool = false # {{{2

	def new(bufnr: number, options: dict<any>) # {{{2
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", 0)
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmethod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef

	def SetFilter(F: func(Window, string): bool) # {{{2
		this.SetOptions({
			filter: (_: number, key: string) => F(this, key)
		})
	enddef

	def SetOptions(options: dict<any>) # {{{2
		popup_setoptions(this.winnr, options)
	enddef

	def SetBuf(bufnr: number) # {{{2
		for F in this._on_set_buf_pre
			F(this)
		endfor

		popup_setbuf(this.winnr, bufnr)

		for F in this._on_set_buf_after
			F(this)
		endfor
	enddef

	def SetTitle(title: string) # {{{2
		this.SetOptions({title: title})
	enddef

	def GetOptions() # {{{2
		return popup_getoptions(this.winnr)
	enddef

	def _CloseCallback(id: number, result: any) # {{{2
		for F in this._on_close
			F(this, result)
		endfor

		this.winnr = -1
	enddef

	def IsOpen(): bool # {{{2
		return this.winnr != -1
	enddef

	def IsHidden(): bool # {{{2
		return this.IsOpen() && this.hidden
	enddef

	def Close(result: any = null) # {{{2
		var r = result
		if r == null
			r = winbufnr(this.winnr)
		endif

		popup_close(this.winnr, r)
		this.winnr = -1
	enddef

	def Hide() # {{{2
		popup_hide(this.winnr)
		this._hidden = true
	enddef

	def Show(): number # {{{2
		popup_show(this.winnr)
		this._hidden = false
	enddef
endclass
