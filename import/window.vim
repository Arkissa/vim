vim9script

import 'buffer.vim' as bf
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

const group = 'PopupWindow'
const hasQuickfix = has('quickfix')
const hasTerminal = has('terminal')

export class WinInfo # {{{1
	var botline: number
	var buffer: bf.Buffer
	var height: number
	var leftcol: number
	var loclist: bool
	var quickfix: bool
	var terminal: bool
	var tabnr: number
	var topline: number
	var variables: dict<any>
	var width: number
	var winbar: bool
	var wincol: number
	var textoff: number
	var winid: number
	var winnr: number
	var winrow: number

	def new( # {{{2
		this.botline
		this.buffer
		this.height
		this.leftcol
		this.loclist
		this.quickfix
		this.terminal
		this.tabnr
		this.topline
		this.variables
		this.width
		this.winbar
		this.wincol
		this.textoff
		this.winid
		this.winnr
		this.winrow
	)
	enddef # }}}
endclass # }}}

class LockWindowSize # {{{1
	static const group = 'LockWindowSize'
	static const event = 'WinResized'

	static def IsLocked(winnr: number): bool # {{{2
		var opts = {
			group: group,
			event: event,
			pattern: winnr->string(),
		}

		var found = false
		try
			found = !autocmd_get(opts)->empty()
		catch /E367/
		endtry

		return found
	enddef # }}}

	static def Lock(winnr: number, height: number, widht: number) # {{{2
		Autocmd.new(event)
			.Group(group)
			.Pattern([winnr->string()])
			.Callback(() => {
				var cmd = []
				if height > 0
					cmd->add($'resize {height}')
				endif

				if widht > 0
					cmd->add($'vertical resize {widht}')
				endif

				if cmd->len() > 0
					win_execute(winnr, cmd->join(' | '))
				endif
			})

		Autocmd.new('WinClosed')
			.Group(group)
			.Pattern([winnr->string()])
			.Callback(function(LockWindowSize.Unlock, [winnr]))
	enddef # }}}

	static def LockHeight(winnr: number, height: number)
		LockWIndowSize.Lock(winnr, height, -1)
	enddef

	static def LockWidth(winnr: number, width: number)
		LockWIndowSize.Lock(winnr, -1, width)
	enddef

	static def Unlock(winnr: number) # {{{2
		Autocmd.Delete([{
			group: group,
			event: event,
			pattern: winnr->string(),
		}])
	enddef # }}}
endclass # }}}

export class Window # {{{1
	var winnr: number
	var _pos: string
	var _height: number

	static var _executeFunction: dict<func()> = {}

	static def ExecuteFunction(id: number): func() # {{{2
		return _executeFunction[id]
	enddef # }}}

	def new(pos: string = '', height: number = 0) # {{{2
		this._pos = pos
		this._height = height
	enddef # }}}

	def newByWinnr(this.winnr) # {{{2
		this.winnr = this.winnr < 1000 ? win_getid(this.winnr) : this.winnr
	enddef # }}}

	def newCurrent() # {{{2
		this.winnr = win_getid()
	enddef # }}}

	def Open(fname: string = '') # {{{2
		execute($'{this._pos} :{this._height ?? ''}new {fname}', 'silent! ')
		this.winnr = win_getid()
		if fname == ''
			this.GetBuffer().SetVar('&bufhidden', 'wipe')
		endif
	enddef # }}}

	def Width(): number # {{{2
		return winwidth(this.winnr)
	enddef # }}}

	def Height(): number #{{{2
		return winheight(this.winnr)
	enddef # }}}

	def SetCursor(lnum: number, col: number) # {{{2
		this.Execute($"eval cursor({lnum}, {col})")
	enddef # }}}

	def SetVar(name: string, value: any) # {{{2
		setwinvar(this.winnr, name, value)
	enddef # }}}

	def GetBuffer(): bf.Buffer # {{{2
		return bf.Buffer.newByBufnr(this.GetBufnr())
	enddef # }}}

	def GetWinType(): string # {{{2
		return win_gettype(this.winnr)
	enddef # }}}

	def GetBufnr(): number # {{{2
		return winbufnr(this.winnr)
	enddef # }}}

	def GetVar(name: string): any # {{{2
		return getwinvar(this.winnr, name)
	enddef # }}}

	def Resize(height: number) # {{{2
		if this.IsOpen()
			this.Execute($'resize {height}', 'silent')
		endif

		this._height = height
	enddef # }}}

	def SetPos(pos: string) # {{{2
		this._pos = pos
	enddef # }}}

	def SetBuf(bufnr: number, au: bool = true) # {{{2
		var winnr = this.winnr->string()
		if au && exists($'#BufWinLeave#{winnr}')
				Autocmd.Do('', 'BufWinLeave', winnr, this)
		endif

		this.Execute($'{au ? '' : 'noautocmd '}buffer! {bufnr}', 'silent')

		if au && exists($'#BufWinEnter#{winnr}')
			Autocmd.Do('', 'BufWinEnter', winnr, this)
		endif
	enddef # }}}

	def SetBuffer(buf: bf.Buffer, au: bool = true) # {{{2
		this.SetBuf(buf.bufnr, au)
	enddef # }}}

	def Close(result: any = null) # {{{2
		var win = this.winnr->string()
		if exists($'#WinClosed#{win}')
			Autocmd.Do('', 'WinClosed', win, (this, result ?? this.GetBufnr()))
		endif

		this.Execute('close!', 'silent!')
	enddef # }}}

	def GetCursorPos(): tuple<number, number> # {{{2
		var [_, lnum, col, _, _] = getcurpos(this.winnr)
		return (lnum, col)
	enddef # }}}

	def IsOpen(): bool # {{{2
		return this.GetInfo() != null_object
	enddef # }}}

	def GetInfo(): WinInfo # {{{2
		var wins = getwininfo(this.winnr)

		if wins->empty()
			return null_object
		endif

		var info = wins[0]

		return WinInfo.new(
			info.botline,
			bf.Buffer.newByBufnr(info.bufnr),
			info.height,
			info.leftcol,
			hasQuickfix && info.loclist,
			hasQuickfix && info.quickfix,
			hasTerminal && info.terminal,
			info.tabnr,
			info.topline,
			info.variables,
			info.width,
			info.winbar,
			info.wincol,
			info.textoff,
			info.winid,
			info.winnr,
			info.winrow,
		)
	enddef # }}}

	def Execute(cmd: string, silent: string = '') # {{{2
		win_execute(this.winnr, cmd, silent)
	enddef # }}}

	def ExecuteCallback(F: func()) # {{{2
		var id = rand()
		_executeFunction[id] = F
		win_execute(this.winnr, $'call(Window.ExecuteFunction({id}), [])')
	enddef # }}}

	def FeedKeys(exe: string, mod: string = 'm') # {{{2
		this.Execute($'feedkeys(''{exe}'', ''{mod}'')')
	enddef # }}}

	def LockSize() # {{{2
		if LockWindowSize.IsLocked(this.winnr)
			return
		endif

		LockWindowSize.Lock(this.winnr, this.Height(), this.Width())
	enddef # }}}

	def LockHeightSize() # {{{2
		if LockWindowSize.IsLocked(this.winnr)
			return
		endif

		LockWindowSize.LockHeight(this.winnr, this.Height())
	enddef # }}}

	def LockWidthSize() # {{{2
		if LockWindowSize.IsLocked(this.winnr)
			return
		endif

		LockWindowSize.LockWidth(this.winnr, this.Width())
	enddef # }}}

	def UnlockSize() # {{{2
		LockWindowSize.Unlock(this.winnr)
	enddef # }}}
endclass # }}}

export class Popup extends Window # {{{1
	var _hidden: bool = false
	var _options: dict<any>

	def new(this._options) # {{{2
		this._options.callback = function(this._CloseCallback, [get(this._options, 'callback', null_function)])
	enddef # }}}

	def Open(fname: string = '') # {{{2
		var buf = fname == ''
			? bf.Buffer.newCurrent()
			: bf.Buffer.new(fname)
		this.winnr = popup_create(buf.bufnr, this._options)

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
		var winnr = this.winnr->string()
		if exists($'#BufWinLeave#{winnr}')
			Autocmd.Do('', 'BufWinLeave', winnr, this)
		endif

		popup_setbuf(this.winnr, bufnr)

		if exists($'#BufWinEnter#{winnr}')
			Autocmd.Do('', 'BufWinEnter', winnr, this)
		endif
	enddef # }}}

	def SetBuffer(buf: bf.Buffer) # {{{2
		this.SetBuf(buf.bufnr)
	enddef # }}}

	def SetTitle(title: string) # {{{2
		this.SetOptions({title: title})
	enddef # }}}

	def GetOptions(): dict<any> # {{{2
		return popup_getoptions(this.winnr)
	enddef # }}}

	def _CloseCallback(F: func(number, any), id: number, result: any) # {{{2
		var win = this.winnr->string()
		if exists($'#WinClosed#{win}')
			Autocmd.Do('', 'WinClosed', win, (this, result ?? this.GetBufnr()))
		endif

		if F != null_function
			F(id, result)
		endif
	enddef # }}}

	def IsHidden(): bool # {{{2
		return this.IsOpen() && this.hidden
	enddef # }}}

	def Close(result: any = null) # {{{2
		popup_close(this.winnr, result)
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
