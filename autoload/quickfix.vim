vim9script

import "./popup.vim"
import "./buffer.vim"
import "./log.vim"

export enum Action
	A('a'),
	R('r'),
	U('u'),
	F('f')

	var Value: string
endenum

export enum Type
	E('E'),
	W('W'),
	I('I'),
	N('N'),
	Empty('')

	var Value: string
	static def FromString(t: string): Type
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

export class QuickfixItem
	var buffer: buffer.Buffer
	var lnum: number
	var col: number
	var end_lnum: number
	var end_col: number
	var text: string
	var module: string
	var vcol: number
	var nr: number
	var type: Type = Type.Empty
	var valid: bool
	var pattern: string
	const user_data: dict<any>

	def new(item: dict<any>)
		this.buffer = buffer.Buffer.newByBufnr(item.bufnr)
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

	def newByBuffer(buf: buffer.Buffer)
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

	def string(): string
		return string(this.ToRow())
	enddef

	def ToRow(): dict<any>
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
	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any>): bool
	def GetList(what: dict<any> = null_dict): any
	def GetItemUnderTheCursor(): QuickfixItem
	def JumpFirst(nr: number = 1)
	def Open(height: number = 0)
	def Close()
	def Window(height: number = 0)
	def IsLocation(): bool
	def Empty(): bool
endinterface

export class Quickfix implements Quickfixer
	var id: number

	def new(what: dict<any> = null_dict)
		if what == null_dict
			setqflist([], ' ')
			this.id = getqflist({all: 1}).id
		else
			this.id = what.id
		endif
	enddef

	def newCurrent()
		this.id = getqflist({all: 1}).id
	enddef

	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool
		var items = entry->mapnew((_, item) => item.ToRow())
		if what == null_dict
			return setqflist(entry, action.Value) == 0
		endif

		if !what->has_key('id')
			what.id = this.id
		endif

		return setqflist(entry, action.Value, what) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any
		if what == null_dict
			return getqflist({id: this.id, items: 1}).items->map((_, item) => QuickfixItem.new(item))
		endif

		var qf = getqflist(what)
		if what->has_key('items')
			qf.items->map((_, item) => QuickfixItem.new(item))
		endif

		return qf
	enddef

	def GetItemUnderTheCursor(): QuickfixItem
		if this.Empty()
			return null_object
		endif

		var b = buffer.Buffer.new()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(nr: number = 1)
		execute($'silent cc {nr}')
	enddef

	def Open(height: number = 0)
		if height != 0
			execute($'copen {height}')
		else
			:copen
		endif
	enddef

	def Close()
		:cclose
	enddef

	def Window(height: number = 0)
		if height != 0
			execute($'cwindow {height}')
		else
			:cwindow
		endif
	enddef

	def IsLocation(): bool
		return false
	enddef

	def Empty(): bool
		return this.GetList() == null_list
	enddef
endclass

export class Location implements Quickfixer
	var winnr: number
	var id: number

	def new(this.winnr, what: dict<any> = null_dict)
		if what == null_dict
			setloclist(this.winnr, [], ' ')
			this.id = getloclist(this.winnr, {all: 1}).id
		else
			this.id = what.id
		endif
	enddef

	def newCurrent()
		this.id = getloclist(winnr(), {all: 1}).id
	enddef

	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool
		var items = entry->mapnew((_, item) => item.ToRow())
		if what == null_dict
		   return setloclist(this.winnr, items, action.Value) == 0
		endif

		if !what->has_key('id')
			what.id = this.id
		endif

		return setloclist(this.winnr, items, action.Value, what) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any
		if what == null_dict
			return getloclist(this.winnr, {id: this.id, items: 1}).items->map((_, item) => QuickfixItem.new(item))
		endif

		var loc = getloclist(this.winnr, what)
		if what->has_key('items')
			loc.items->map((_, item) => QuickfixItem.new(item))
		endif

		return loc
	enddef

	def GetItemUnderTheCursor(): QuickfixItem
		if this.Empty()
			return null_object
		endif

		var b = buffer.Buffer.new()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(nr: number = 1)
		exe $"silent ll {nr}"
	enddef

	def Open(height: number = 0)
		if height != 0
			exe $"lopen {height}"
		else
			:lopen
		endif
	enddef

	def Close()
		:lclose
	enddef

	def Window(height: number = 0)
		if height != 0
			exe $"lwindow  {height}"
		else
			:lwindow
		endif
	enddef

	def IsLocation(): bool
		return true
	enddef

	def Empty(): bool
		return this.GetList() == null_list
	enddef
endclass

export class Text
	static def GetLnum(item: QuickfixItem): string
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

	static def GetFname(bufname: string, limit: number): string
		var len = bufname->strdisplaywidth()
		if len <= limit
			return bufname
		endif

		return $"…{bufname[len - limit + 1 : ]}"
	enddef

	static def GetText(text: string, limit: number): string
		var len = text->strdisplaywidth()
		if len <= limit
			return text
		endif

		return $"{text}…"
	enddef

	static def Func(info: dict<any>): list<string>
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
export class Previewer
	static var _prop_name = "quickfix.Previewer"
	static var _qf: Quickfixer
	static var _window: popup.Window

	static def _Filter(win: popup.Window, key: string): bool
		if ["\<C-u>", "\<C-d>"]->index(key) != -1
			win.FeedKeys(key, "mx")
			return true
		endif

		return false
	enddef

	static def _WinOption(win: popup.Window)
		win.SetVar("&number", 1)
		win.SetVar("&cursorline", 1)
		win.SetVar("&relativenumber", 0)
	enddef

	static def _DetectFiletype(win: popup.Window)
		timer_start(0, (_) => {
			var ft = win.GetVar('&filetype')
			if ft == ""
				win.Execute("filetype detect")
			endif
		})
	enddef

	static def _AddHightlightText(win: popup.Window)
		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
			return
		endif

		if item.lnum == 0 || item.col == 0
			return
		endif

		prop_add(item.lnum, item.col, {
			type: _prop_name,
			end_lnum: item.end_lnum != 0 ? item.end_lnum : item.lnum,
			end_col: item.end_col != 0 ? item.end_col : item.col,
			bufnr: win.GetBufnr(),
		})
	enddef

	static def _RemoveHightlightText(win: popup.Window)
		prop_remove({
			type: _prop_name,
			bufnr: win.GetBufnr()
		})
	enddef

	static def _DeleteHightlightName(win: popup.Window, _: any)
		prop_remove({
			type: _prop_name,
			bufnr: win.GetBufnr()
		})
		prop_type_delete(_prop_name)
	enddef

	static def Open()
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
		_window = popup.Window.new(wininfo.bufnr, {
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
		_window.OnSetBufAfter(_DetectFiletype, _WinOption, _AddHightlightText)
		_window.OnClose(_DeleteHightlightName)
		_CreateAutocmd(_window, winbufnr(winId))
		SetCursorUnderBuff()
	enddef

	static def _CreateAutocmd(win: popup.Window, bufnr: number)
		var group = "Quickfix.Previewer"
		var events = [
			{
				bufnr: bufnr,
				group: group,
				event: "CursorMoved",
				cmd: "Previewer.SetCursorUnderBuff()",
			},
			{
				bufnr: bufnr,
				group: group,
				event: ["WinLeave", "WinClosed", "WinLeave", "BufWipeout", "BufHidden"],
				cmd: "Previewer.Close()",
			}
		]

		autocmd_add(events)

		win.OnClose((_: popup.Window, _: any) => {
			autocmd_delete([{group: group}])
		})
	enddef

	static def SetCursorUnderBuff()
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

	static def Toggle()
		if _window != null_object && _window.IsOpen()
			Close()
		else
			Open()
		endif
	enddef

	static def Close()
		if _window != null_object && _window.IsOpen()
			_window.Close()
		endif
	enddef
endclass
