vim9script

import './log.vim'
import './autocmd.vim'
import './window.vim'
import './buffer.vim'

type Buffer = buffer.Buffer # {{{1
type Autocmd = autocmd.Autocmd # {{{1

export enum Action # {{{1
	A('a'),
	R('r'),
	U('u'),
	F('f')

	var Value: string
endenum

export enum Type # {{{1
	E('E'), # {{{2
	W('W'), # {{{2
	I('I'), # {{{2
	N('N'), # {{{2
	Empty('') # {{{2

	var Value: string # {{{2
	static def FromString(t: string): Type # {{{2
		if t == 'E'
			return E
		elseif t == 'W'
			return W
		elseif t == 'I'
			return I
		elseif t == 'N'
			return N
		else
			return Empty
		endif
	enddef
endenum

export class QuickfixItem # {{{1
	var buffer: Buffer # {{{2
	var lnum: number # {{{2
	var col: number # {{{2
	var end_lnum: number # {{{2
	var end_col: number # {{{2
	var text: string # {{{2
	var module: string # {{{2
	var vcol: number # {{{2
	var nr: number # {{{2
	var type: Type = Type.Empty # {{{2
	var valid: bool # {{{2
	var pattern: string # {{{2
	const user_data: dict<any> # {{{2

	def new(item: dict<any>) # {{{2
		this.buffer = Buffer.newByBufnr(item.bufnr)
		this.lnum = item.lnum
		this.col = item.col
		this.end_lnum = item.end_lnum
		this.end_col = item.end_col
		this.text = item.text
		this.valid = item.valid
		this.type = has_key(item, 'type') ? Type.FromString(item.type) : ''
		this.vcol = has_key(item, 'vcol') ? item.vcol : 0
		this.module = has_key(item, 'module') ? item.module : ''
		this.user_data = has_key(item, 'user_data') ? item.user_data : null_dict
		this.pattern = has_key(item, 'pattern') ? item.pattern : ''
		this.nr = has_key(item, 'nr') ? item.nr : 0
	enddef

	def newByBuffer(buf: buffer.Buffer) # {{{2
		var [lnum, col] = buf.LastCursorPosition()

		this.buffer = buf
		this.lnum = lnum
		this.col = col
		this.end_lnum = 0
		this.end_col = 0
		this.nr = 0
		this.text = buf.GetOneLine(lnum)
		this.valid = 1
	enddef

	def string(): string # {{{2
		return string(this.ToRow())
	enddef

	def ToRow(): dict<any> # {{{2
		return {
			bufnr: this.buffer.bufnr,
			lnum: this.lnum,
			end_lnum: this.end_lnum,
			col: this.col,
			end_col: this.end_col,
			module: this.module,
			vcol: this.vcol,
			text: this.text,
			nr: this.nr,
			type: this.type.Value,
			valid: this.valid,
			user_data: this.user_data
		}
	enddef
endclass

export interface Quickfixer
	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any>): bool # {{{2
	def GetList(what: dict<any> = null_dict): any # {{{2
	def GetItemUnderTheCursor(): QuickfixItem # {{{2
	def JumpFirst(nr: number = 1) # {{{2
	def Open(height: number = 0) # {{{2
	def Close() # {{{2
	def Window(height: number = 0) # {{{2
	def IsLocation(): bool # {{{2
	def Empty(): bool # {{{2
endinterface

export class Quickfix implements Quickfixer # {{{1
	var id: number # {{{2

	def new(what: dict<any> = null_dict) # {{{2
		if what == null_dict
			setqflist([], ' ')
			this.id = getqflist({all: 1}).id
		else
			this.id = what.id
		endif
	enddef

	def newCurrent() # {{{2
		this.id = getqflist({all: 1}).id
	enddef

	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool # {{{2
		var items = entry->mapnew((_, item) => item.ToRow())
		if what == null_dict
			return setqflist(items, action.Value) == 0
		endif

		if !what->has_key('id')
			what.id = this.id
		endif

		return setqflist(items, action.Value, what) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any # {{{2
		if what == null_dict
			return getqflist({id: this.id, items: 1}).items->map((_, item) => QuickfixItem.new(item))
		endif

		var qf = getqflist(what)
		if what->has_key('items')
			qf.items->map((_, item) => QuickfixItem.new(item))
		endif

		return qf
	enddef

	def GetItemUnderTheCursor(): QuickfixItem # {{{2
		if this.Empty()
			return null_object
		endif

		var b = Buffer.newCurrent()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(nr: number = 1) # {{{2
		execute($'silent cc {nr}')
	enddef

	def Open(height: number = 0) # {{{2
		if height != 0
			execute($'copen {height}')
		else
			:copen
		endif
	enddef

	def Close() # {{{2
		:cclose
	enddef

	def Window(height: number = 0) # {{{2
		if height != 0
			execute($'cwindow {height}')
		else
			:cwindow
		endif
	enddef

	def IsLocation(): bool # {{{2
		return false
	enddef

	def Empty(): bool # {{{2
		return this.GetList() == null_list
	enddef
endclass

export class Location implements Quickfixer # {{{1
	var winnr: number # {{{2
	var id: number # {{{2

	def new(this.winnr, what: dict<any> = null_dict) # {{{2
		if what == null_dict
			setloclist(this.winnr, [], ' ')
			this.id = getloclist(this.winnr, {all: 1}).id
		else
			this.id = what.id
		endif
	enddef

	def newCurrent() # {{{2
		this.id = getloclist(winnr(), {all: 1}).id
	enddef

	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool # {{{2
		var items = entry->mapnew((_, item) => item.ToRow())
		if what == null_dict
		   return setloclist(this.winnr, items, action.Value) == 0
		endif

		if !what->has_key('id')
			what.id = this.id
		endif

		return setloclist(this.winnr, items, action.Value, what) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any # {{{2
		if what == null_dict
			return getloclist(this.winnr, {id: this.id, items: 1}).items->map((_, item) => QuickfixItem.new(item))
		endif

		var loc = getloclist(this.winnr, what)
		if what->has_key('items')
			loc.items->map((_, item) => QuickfixItem.new(item))
		endif

		return loc
	enddef

	def GetItemUnderTheCursor(): QuickfixItem # {{{2
		if this.Empty()
			return null_object
		endif

		var b = Buffer.newCurrent()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(nr: number = 1) # {{{2
		exe $"silent ll {nr}"
	enddef

	def Open(height: number = 0) # {{{2
		if height != 0
			exe $"lopen {height}"
		else
			:lopen
		endif
	enddef

	def Close() # {{{2
		:lclose
	enddef

	def Window(height: number = 0) # {{{2
		if height != 0
			exe $"lwindow  {height}"
		else
			:lwindow
		endif
	enddef

	def IsLocation(): bool # {{{2
		return true
	enddef

	def Empty(): bool # {{{2
		return this.GetList() == null_list
	enddef
endclass

export class Text # {{{1
	static def GetLnum(item: QuickfixItem): string # {{{2
		var str = ""

		if item.lnum > 0
			str ..= item.lnum->string()
		endif

		if item.end_lnum > 0
			str ..= $"-{item.end_lnum}"
		endif

		if item.col > 0
			str ..= $":{item.col}"
		endif

		if item.end_col > 0
			str ..= $"-{item.end_col}"
		endif

		return str
	enddef

	static def GetFname(bufname: string, limit: number): string # {{{2
		var len = bufname->strdisplaywidth()
		if len <= limit
			return bufname
		endif

		return $"…{bufname[len - limit + 1 : ]}"
	enddef

	static def GetText(text: string, limit: number): string # {{{2
		var len = text->strdisplaywidth()
		if len <= limit
			return text
		endif

		return $"{text}…"
	enddef

	static def Func(info: dict<any>): list<string> # {{{2
		var qf: Quickfixer = info.quickfix == 1 ? Quickfix.new({id: info.id}) : Location.new(info.winid, {id: info.id})

		var qflist = qf.GetList({id: info.id, items: 1})

		var items = qflist.items
		var maxFnameWidth = float2nr(floor(min([95, &columns / 4])))
		var max_row = items
			->mapnew((_, item) => Text.GetLnum(item))
			->map((_, row) => row->strdisplaywidth())
			->max()
		var max_type = items
			->mapnew((_, item) => item.type.Value->strdisplaywidth())
			->max()
		max_type = max_type == 0 ? 0 : max_type + 1

		return items[info.start_idx - 1 : info.end_idx]->mapnew((_, item) => {
				var fname: string
				if item.valid
					fname = Text.GetFname(fnamemodify(item.buffer.name, ":~:."), maxFnameWidth)
				endif

				var line = $"%-{max_type}s%-{maxFnameWidth}s │%{max_row}s│%{min([99, item.text->strdisplaywidth() + 1])}s"
				return printf(line, item.type.Value, fname, Text.GetLnum(item), Text.GetText(item.text, 99))
			})
	enddef
endclass

# peek quickfix buffer with popup window.
export class Previewer # {{{1
	static var _prop_name = "quickfix.Previewer" # {{{2
	static var _qf: Quickfixer # {{{2
	static var _window: window.Popup # {{{2

	static def _Filter(win: window.Popup, key: string): bool # {{{2
		if ["\<C-u>", "\<C-d>"]->index(key) != -1
			win.FeedKeys(key, "mx")
			return true
		endif

		return false
	enddef

	static def _WinOption(win: window.Popup) # {{{2
		win.SetVar("&number", true)
		win.SetVar("&cursorline", true)
		win.SetVar("&relativenumber", false)
	enddef

	static def _DetectFiletype(win: window.Popup) # {{{2
		timer_start(0, (_) => {
			var ft = win.GetVar('&filetype')
			if ft == ""
				win.Execute("filetype detect")
			endif
		})
	enddef

	static def _AddHightlightText(win: window.Popup) # {{{2
		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
			return
		endif

		if item.lnum == 0 || item.col == 0
			return
		endif

		prop_add(item.lnum, item.col, {
			type: _prop_name,
			end_lnum: item.end_lnum ?? item.lnum,
			end_col: item.end_col ?? item.col,
			bufnr: win.GetBufnr(),
		})
	enddef

	static def _RemoveHightlightText(win: window.Popup) # {{{2
		prop_remove({
			type: _prop_name,
			bufnr: win.GetBufnr()
		})
	enddef

	static def _DeleteHightlightName(win: window.Popup, _: any) # {{{2
		prop_remove({
			type: _prop_name,
			bufnr: win.GetBufnr()
		})
		prop_type_delete(_prop_name)
	enddef

	static def Open() # {{{2
		var winId = win_getid()
		var wt = win_gettype(winId)
		if ["quickfix", "loclist"]->index(wt) == -1
			return
		endif

		_qf = wt == "loclist"
			? Location.newCurrent()
			: Quickfix.newCurrent()
		var item = _qf.GetItemUnderTheCursor()
		if _qf.Empty() || item == null_object
			return
		endif

		prop_type_add(_prop_name, {
			highlight: "Cursor",
			override: true,
		})

		var wininfo = getwininfo(winId)[0]
		var lines = float2nr(getwinvar(winId, "&lines") * 0.5)
		_window = window.Popup.new(wininfo.bufnr, {
			pos: "botleft",
			padding: [1, 1, 1, 1],
			border: [1, 1, 1, 1],
			borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
			borderhighlight: ["Title", "Title", "Title", "Title"],
			maxheight: lines,
			minheight: wininfo.width - 5,
			minwidth: wininfo.width - 5,
			maxwidth: wininfo.width - 5,
			col: wininfo.wincol,
			line: wininfo.winrow - 2,
		})

		_window.SetFilter(_Filter)
		_window.OnSetBufPre(_RemoveHightlightText)
		_window.OnSetBufPost(_DetectFiletype, _WinOption, _AddHightlightText)
		_window.OnClose(_DeleteHightlightName)
		_CreateAutocmd(_window, winbufnr(winId))
		_SetCursorUnderBuff()
	enddef

	static def _CreateAutocmd(win: window.Popup, bufnr: number) # {{{2
		var group = "Quickfix.Previewer"
		Autocmd.new('CursorMoved')
			.Group(group)
			.Bufnr(bufnr)
			.Callback(_SetCursorUnderBuff)

		Autocmd.newMulti(["WinLeave", "WinClosed", "WinLeave", "BufWipeout", "BufHidden"])
			.Group(group)
			.Bufnr(bufnr)
			.Callback(Close)

		win.OnClose((_: window.Popup, _: any) => {
			autocmd_delete([{group: group}])
		})
	enddef

	static def _SetCursorUnderBuff() # {{{2
		if _window == null_object || _qf == null_object || !_window.IsOpen()
			log.Error("Unable to set the qfitem buffer under cursor line for preview window.")
			return
		endif

		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
			return
		endif

		_window.SetBuf(item.buffer.bufnr)
		var bufinfo = item.buffer.GetInfo()
		_window.SetTitle($" [{item.lnum}/{bufinfo.linecount}] buffer {item.buffer.bufnr}: {fnamemodify(bufinfo.name, ":~:.")} {bufinfo.changed ? "[+]" : ""}")
		_window.SetCursor(item.lnum, item.col)
		_window.FeedKeys("z.", "mx")
	enddef

	static def Toggle() # {{{2
		if _window != null_object && _window.IsOpen()
			Close()
		else
			Open()
		endif
	enddef

	static def Close() # {{{2
		if _window != null_object && _window.IsOpen()
			_window.Close()
		endif
	enddef
endclass
