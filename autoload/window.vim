vim9script

import './buffer.vim'
import './autocmd.vim'

type Autocmd = autocmd.Autocmd

export class Window # {{{1
	var winnr: number = -1 # {{{2
	var _on_set_buf_pre: list<func> # {{{2
	var _on_set_buf_after: list<func> # {{{2
	var _on_close: list<func> # {{{2
	var _buf: buffer.Buffer # {{{2
	static const group = 'WindowClass' # {{{2

	def _Init() # {{{2
		Autocmd.new('WinClosed')
			.Group(group)
			.Pattern([string(this.winnr)])
			.Once()
			.Callback(() => {
				this.Close()
			})
	enddef # }}}

	def new(pos: string = '', height: number = 0, name: string = '') # {{{2
		this._New(pos, height, name)
		this._Init()
		this._buf = buffer.Buffer.newByBufnr(this.GetBufnr())
	enddef # }}}

	def newByBufnr(bufnr: number, pos: string = '', height: number = 0) # {{{2
		this._buf = buffer.Buffer.newByBufnr(bufnr)
		this._New(pos, height, this._buf.name)
		this._Init()
	enddef # }}}

	def newByBuffer(buf: buffer.Buffer, pos: string = '', height: number = 0) # {{{2
		this._buf = buf
		this._New(pos, height, this._buf.name)
		this._Init()
	enddef # }}}

	def newWrap(this.winnr) # {{{2
		this.winnr = this.winnr < 1000 ? win_getid(this.winnr) : this.winnr
		this._Init()
		this._buf = buffer.Buffer.newByBufnr(this.GetBufnr())
	enddef # }}}

	def newCurrent() # {{{2
		this.winnr = win_getid()
		this._Init()
	enddef # }}}

	def _New(pos: string = '', height: number = 0, name: string = '') # {{{2
		execute(var cmd = $'silent! {pos} :{height ?? ''}new {name}')
		this.winnr = win_getid()
		if name == ''
			setbufvar(this.GetBufnr(), '&bufhidden', 'wipe')
		endif
	enddef # }}}

	def SetCursor(lnum: number, col: number) # {{{2
		this.Execute($"eval cursor({lnum}, {col})")
	enddef # }}}

	def SetVar(name: string, value: any) # {{{2
		setwinvar(this.winnr, name, value)
	enddef # }}}

	def GetBuffer(): buffer.Buffer # {{{2
		return this._buf
	enddef # }}}

	def GetBufnr(): number # {{{2
		return winbufnr(this.winnr)
	enddef # }}}

	def GetVar(name: string): any # {{{2
		return getwinvar(this.winnr, name)
	enddef # }}}

	def Resize(height: number) # {{{2
		this.Execute($'silent resize {height}')
	enddef # }}}

	def OnSetBufPre(...f: list<func>) # {{{2
		extend(this._on_set_buf_pre, f)
	enddef # }}}

	def OnSetBufPost(...f: list<func>) # {{{2
		extend(this._on_set_buf_after, f)
	enddef # }}}

	def OnClose(...f: list<func>) # {{{2
		extend(this._on_close, f)
	enddef # }}}

	def SetBuf(bufnr: number) # {{{2
		for F in this._on_set_buf_pre
			F(this)
		endfor

		this.Execute($'silent! buffer! {bufnr}')
		this._buf = buffer.Buffer.newByBufnr(bufnr)

		for F in this._on_set_buf_after
			F(this)
		endfor
	enddef # }}}

	def SetBuffer(buf: buffer.Buffer)
		for F in this._on_set_buf_pre
			F(this)
		endfor

		this.Execute($'silent! buffer! {buf.bufnr}')
		this._buf = buf

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
	enddef # }}}

	def IsOpen(): bool # {{{2
		return this.winnr != -1
	enddef # }}}

	def Execute(cmd: string) # {{{2
		win_execute(this.winnr, cmd)
	enddef # }}}

	def FeedKeys(exe: string, mod: string = 'm') # {{{2
		this.Execute($'feedkeys(''{exe}'', ''{mod}'')')
	enddef # }}}
endclass # }}}

export class Popup extends Window # {{{1
	var _hidden: bool = false # {{{2

	def new(bufnr: number, options: dict<any>) # {{{2
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", 0)
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmethod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef # }}}

	def SetFilter(F: func(Popup, string): bool) # {{{2
		this.SetOptions({
			filter: (_: number, key: string) => F(this, key)
		})
	enddef # }}}

	def SetOptions(options: dict<any>) # {{{2
		popup_setoptions(this.winnr, options)
	enddef # }}}

	def SetBuf(bufnr: number) # {{{2
		for F in this._on_set_buf_pre
			F(this)
		endfor

		popup_setbuf(this.winnr, bufnr)

		for F in this._on_set_buf_after
			F(this)
		endfor
	enddef # }}}

	def SetTitle(title: string) # {{{2
		this.SetOptions({title: title})
	enddef # }}}

	def GetOptions() # {{{2
		return popup_getoptions(this.winnr)
	enddef # }}}

	def _CloseCallback(id: number, result: any) # {{{2
		for F in this._on_close
			F(this, result)
		endfor

		this.winnr = -1
	enddef # }}}

	def IsOpen(): bool # {{{2
		return this.winnr != -1
	enddef # }}}

	def IsHidden(): bool # {{{2
		return this.IsOpen() && this.hidden
	enddef # }}}

	def Close(result: any = null) # {{{2
		var r = result
		if r == null
			r = winbufnr(this.winnr)
		endif

		popup_close(this.winnr, r)
		this.winnr = -1
	enddef # }}}

	def Hide() # {{{2
		popup_hide(this.winnr)
		this._hidden = true
	enddef # }}}

	def Show(): number # {{{2
		popup_show(this.winnr)
		this._hidden = false
	enddef # }}}
endclass # }}}
