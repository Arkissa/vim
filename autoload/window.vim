vim9script

import './buffer.vim'
import './autocmd.vim'

type Autocmd = autocmd.Autocmd

export class Window
	var winnr: number = -1

	def new(pos: string = '', height: number = 0, name: string = '')
		var buf = buffer.Buffer.newByBufnr(this.GetBufnr())
		this._New(pos, height, name ?? buf.name)
	enddef

	def newByBufnr(bufnr: number, pos: string = '', height: number = 0)
		var buf = buffer.Buffer.newByBufnr(bufnr)
		this._New(pos, height, buf.name)
	enddef

	def newByBuffer(buf: buffer.Buffer, pos: string = '', height: number = 0)
		this._New(pos, height, buf.name)
	enddef

	def newWrap(this.winnr)
		this.winnr = this.winnr < 1000 ? win_getid(this.winnr) : this.winnr
	enddef

	def newCurrent()
		this.winnr = win_getid()
	enddef

	def _New(pos: string = '', height: number = 0, name: string = '')
		execute($'silent! {pos} :{height ?? ''}new {name}')
		this.winnr = win_getid()
		if name == ''
			setbufvar(this.GetBufnr(), '&bufhidden', 'wipe')
		endif
	enddef

	def SetCursor(lnum: number, col: number)
		this.Execute($"eval cursor({lnum}, {col})")
	enddef

	def SetVar(name: string, value: any)
		setwinvar(this.winnr, name, value)
	enddef

	def GetBuffer(): buffer.Buffer
		return buffer.Buffer.newByBufnr(this.GetBufnr())
	enddef

	def GetBufnr(): number
		return winbufnr(this.winnr)
	enddef

	def GetVar(name: string): any
		return getwinvar(this.winnr, name)
	enddef

	def Resize(height: number)
		this.Execute($'silent resize {height}')
	enddef

	def SetBuf(bufnr: number)
		var winnr = this.winnr->string()
		if exists($'#BufWinLeave#{winnr}')
			Autocmd.Do('', 'BufWinLeave', [winnr], this)
		endif

		this.Execute($'silent! buffer! {bufnr}')

		if exists($'#BufWinEnter#{winnr}')
			Autocmd.Do('', 'BufWinEnter', [winnr], this)
		endif
	enddef

	def SetBuffer(buf: buffer.Buffer)
		this.SetBuf(buf.bufnr)
	enddef

	def Close(result: any = null)
		var win = this.winnr->string()
		if exists($'#WinClosed#{win}')
			Autocmd.Do('', 'WinClosed', [win], (this, result ?? this.GetBufnr()))
		endif

		this.Execute('silent! close!')
		this.winnr = -1
	enddef

	def GetCursorPos(): tuple<number, number>
		var [_, lnum, col, _, _] = getcurpos(this.winnr)
		return (lnum, col)
	enddef

	def IsOpen(): bool
		return this.winnr != -1
	enddef

	def Execute(cmd: string)
		win_execute(this.winnr, cmd)
	enddef

	def FeedKeys(exe: string, mod: string = 'm')
		this.Execute($'feedkeys(''{exe}'', ''{mod}'')')
	enddef
endclass

export class Popup extends Window
	var _hidden: bool = false

	def new(bufnr: number, options: dict<any>)
		options.callback = this._CloseCallback
		this.winnr = popup_create(bufnr, options)
		this.SetVar("&foldenable", 0)
		this.SetVar("&foldcolumn", 0)
		this.SetVar("&foldmethod", "manual")
		this.SetVar("&signcolumn", "no")
	enddef

	def SetFilter(F: func(Popup, string): bool)
		this.SetOptions({
			filter: (_: number, key: string) => F(this, key)
		})
	enddef

	def SetOptions(options: dict<any>)
		popup_setoptions(this.winnr, options)
	enddef

	def SetBuf(bufnr: number)
		var winnr = this.winnr->string()
		if exists($'#BufWinLeave#{winnr}')
			Autocmd.Do('', 'BufWinLeave', [winnr], this)
		endif

		popup_setbuf(this.winnr, bufnr)

		if exists($'#BufWinEnter#{winnr}')
			Autocmd.Do('', 'BufWinEnter', [winnr], this)
		endif
	enddef

	def SetBuffer(buf: buffer.Buffer)
		this.SetBuf(buf.bufnr)
	enddef

	def SetTitle(title: string)
		this.SetOptions({title: title})
	enddef

	def GetOptions()
		return popup_getoptions(this.winnr)
	enddef

	def _CloseCallback(id: number, result: any)
		var win = this.winnr->string()
		if exists($'#WinClosed#{win}')
			Autocmd.Do('', 'WinClosed', [win], (this, result ?? this.GetBufnr()))
		endif
	enddef

	def IsOpen(): bool
		return this.winnr != -1
	enddef

	def IsHidden(): bool
		return this.IsOpen() && this.hidden
	enddef

	def Close(result: any = null)
		popup_close(this.winnr, result)
		this.winnr = -1
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
