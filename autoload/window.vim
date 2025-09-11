vim9script

export class Window # {{{1
	var winnr: number = -1 # {{{2
	var _on_set_buf_pre: list<func> # {{{2
	var _on_set_buf_after: list<func> # {{{2
	var _on_close: list<func> # {{{2

	def new(height: number = 0) # {{{2
		this._New(height)
	enddef

	def newBufnr(bufnr: number, height: number = 0) # {{{2
		this._New(height)

		var bufnr = winbufnr()
		this.Execute($'buffer {bufnr}')
		execute($'bwipeout {bufnr()}')
	enddef

	def _New(height: number = 0) # {{{2
		var cmd = 'new'
		if height > 0
			cmd = $'{height}new'
		endif

		execute(cmd)
		this.winnr = winnr()
	enddef

	def SetCursor(lnum: number, col: number) # {{{2
		this.Execute($"eval cursor({lnum}, {col})")
	enddef

	def SetVar(name: string, value: any) # {{{2
		setwinvar(this.winnr, name, value)
	enddef

	def GetBufnr(): number # {{{2
		return winbufnr(this.winnr)
	enddef

	def GetVar(name: string): any # {{{2
		return getwinvar(this.winnr, name)
	enddef

	def OnSetBufPre(...f: list<func>) # {{{2
		extend(this._on_set_buf_pre, f)
	enddef

	def OnSetBufAfter(...f: list<func>) # {{{2
		extend(this._on_set_buf_after, f)
	enddef

	def OnClose(...f: list<func>) # {{{2
		extend(this._on_close, f)
	enddef

	def SetBuf(bufnr: number) # {{{2
		for F in this._on_set_buf_pre
			F(this)
		endfor

		this.Execute($'buffer {bufnr}')

		for F in this._on_set_buf_after
			F(this)
		endfor
	enddef

	def Close(result: any = null) # {{{2
		var r = result
		if r == null
			r = winbufnr(this.winnr)
		endif

		this.Execute('close!')
		for F in this._on_close
			F(this, result)
		endfor

		this.winnr = -1
	enddef

	def IsOpen(): bool # {{{2
		return this.winnr != -1
	enddef

	def Execute(cmd: string) # {{{2
		win_execute(this.winnr, cmd)
	enddef

	def FeedKeys(exe: string, mod: string = 'm') # {{{2
		this.Execute($'feedkeys(''{exe}'', ''{mod}'')')
	enddef
endclass
