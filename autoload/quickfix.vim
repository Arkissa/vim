vim9script

import "./popup.vim"
import "./buffer.vim"
import "./log.vim"

export enum Action
	A("a"),
	R("r"),
	U("u"),
	F("f")

	var Value: string
endenum

export enum Type
	E("E"),
	W("W"),
	I("I"),
	N("N"),
	Empty("")

	var Value: string
	static def FromString(t: string): Type
		if t == "E"
			return E
		elseif t == "W"
			return W
		elseif t == "I"
			return I
		elseif t == "N"
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
	var vcol: bool
	var nr: number
	var type: Type
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
		this.type = has_key(item, "type") ? Type.FromString(item.type) : ""
		this.vcol = has_key(item, "vcol") ? item.vcol : ""
		this.module = has_key(item, "module") ? item.module : ""
		this.user_data = has_key(item, "user_data") ? item.user_data : null_dict
		this.pattern = has_key(item, "pattern") ? item.pattern : ""
		this.nr = has_key(item, "nr") ? item.nr : 0
	enddef

	def ToRow(): dict<any>
		return {
			bufnr: this.buffer.bufnr,
			lnum: this.lnum
			end_lnum: this.end_lnum,
			col: this.col,
			end_col: this.end_col,
			module: this.module,
			vcol: this.vcol,
			nr: this.nr,
			type: this.type.Value,
			valid: this.valid,
			user_data: this.user_data
		}
	enddef
endclass

export interface Quickfixer
	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any>): bool
	def GetList(what: dict<any> = null_dict): list<QuickfixItem>
	def GetItemUnderTheCursor(): QuickfixItem
	def JumpFirst(bufnr: number)
	def Open(height: number = 0)
	def Close()
	def Window(height: number = 0)
	def IsLocation(): bool
	def Empty(): bool
endinterface

export class Quickfix implements Quickfixer
	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool
		var items = entry->map((_, item) => item.ToRow())
		return (what == null_dict
			? setqflist(items, action.Value, what)
			: setqflist(items, action.Value)) == 0
	enddef

	def GetList(what: dict<any> = null_dict): list<QuickfixItem>
		var qfitems: any = what == null_dict
				? getqflist()
				: getqflist(what)

		if type(qfitems) == type({})
			qfitems = [qfitems]
		endif

		return qfitems->mapnew((_, item) => QuickfixItem.new(item))
	enddef

	def GetItemUnderTheCursor(): QuickfixItem
		if this.Empty()
			return null_object
		endif

		var b = buffer.Buffer.new()
		var item = this.GetList()[b.GetLinePosition() - 1]
		if !item.valid || item.buffer.IsDirectory()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(bufnr: number)
		:silent cc bufnr
	enddef

	def Open(height: number = 0)
		if height != 0
			:copen height
		else
			:copen
		endif
	enddef

	def Close()
		:cclose
	enddef

	def Window(height: number = 0)
		if height != 0
			:cwindow height
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

	def new(this.winnr)
	enddef

	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool
		var items = entry->map((_, item) => item.ToRow())
		return (what == null_dict
			? setloclist(this.winnr, items, action.Value)
			: setloclist(this.winnr, items, action.Value, what)) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any
		var locitems: any = what == null_dict
			? getloclist(this.winnr)
			: getloclist(this.winnr, what)

		if type(locitems) == type({})
			locitems = [locitems]
		endif

		return locitems->mapnew((_, item) => QuickfixItem.new(item))
	enddef

	def GetItemUnderTheCursor(): QuickfixItem
		if this.Empty()
			return null_object
		endif

		var b = buffer.Buffer.new()
		var item = this.GetList()[b.GetLinePosition() - 1]
		if !item.valid || item.buffer.IsDirectory()
			return null_object
		endif

		return item
	enddef

	def JumpFirst(bufnr: number)
		:silent ll bufnr
	enddef

	def Open(height: number = 0)
		if height != 0
			:lopen height else
			:lopen
		endif
	enddef

	def Close()
		:lclose
	enddef

	def Window(height: number = 0)
		if height != 0
			:lwindow height
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

# quickfixtextfunc
def GetBufName(bufnr: number): string
	return fnamemodify(bufname(bufnr), ":~:.")
enddef

def GetLnumAndColStr(item: dict<any>): string
	var s: list<string> = []

	var lnum = item->has_key("lnum") ? item.lnum : 0
	var col = item->has_key("col") ? item.col : 0

	if lnum > 0
		s->add(lnum->string())
	endif

	if col > 0
		s->add(col->string())
	endif

	return s->join(':')
enddef

def GetAllMaxLengths(qflist: list<dict<any>>): dict<number>
	var lens = {
		row_col: GetLnumAndColStr(qflist[0])->len(),
		type: qflist[0].type->len()
	}

	for item in qflist[1 : ]
		var row_col = GetLnumAndColStr(item)->len()
		if lens.row_col < row_col
			lens.row_col = row_col
		endif

		var type_len = item.type->len()
		if lens.type < type_len
			lens.type = type_len
		endif
	endfor

	return lens
enddef

def GetFname(bufname: string, limit: number): string
	var len = bufname->len()
	if len <= limit
		return bufname
	endif

	return $"…{bufname[len - limit + 1 : ]}"
enddef

export def TextFunc(info: dict<any>): list<string>
	var information = info->copy()
	if !information->has_key('items')
		information['items'] = 1
	endif

	var qflist = getqflist(information).items
	if qflist->len() == 0
		return []
	endif

	var lens = GetAllMaxLengths(qflist)
	var maxFnameWidth = float2nr(floor(min([95, &columns / 4])))
	var tlen = lens.type != 0 ? lens.type + 1 : 0

	return qflist->mapnew((_, item) => {
			var fname = GetFname(GetBufName(item.bufnr), maxFnameWidth)
			var lc = GetLnumAndColStr(item)
			var line = $"%-{tlen}s%-{maxFnameWidth}s │%{lens.row_col}s│%{min([99, item.text->len() + 1])}s"
			return printf(line, item.type, fname, lc, item.text)
		})
enddef

# peek quickfix buffer with popup window.
export class Previewer
	static var _prop_name = "quickfix.Previewer"
	static var _qf: Quickfixer
	static var _window: popup.Window
	static var _config = {
		BorderHighlight: ["Title", "Title", "Title", "Title"],
		BorderChars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
		PropHighlight: "Cursor",
		Number: true,
		CursorLine: true,
	}

	static def Config(c: dict<any>)
		_config->extend(c)
	enddef

	static def _Filter(win: popup.Window, key: string): bool
		if ["\<C-u>", "\<C-d>", "G", "gg"]->index(key) != -1
			win.FeedKeys(key, "mx")
			return true
		endif

		return false
	enddef

	static def _WinOption(win: popup.Window)
		if _config.Number
			win.SetVar("&number", 1)
		endif

		if _config.CursorLine
			win.SetVar("&cursorline", 1)
		endif

		win.SetVar("&relativenumber", 0)
	enddef

	static def _DetectFiletype(win: popup.Window)
		var ft = getbufvar(win.GetBufnr(), '&filetype')
		if ft == ""
			win.Execute("filetype detect")
		endif
	enddef

	static def _AddHightlightText(win: popup.Window)
		var item = _qf.GetItemUnderTheCursor()
		if item == null_object
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
			? Location.new(winId)
			: Quickfix.new()

		if _qf.Empty() || _qf.GetItemUnderTheCursor() == null_object
			return
		endif

		prop_type_add(_prop_name, {
			highlight: _config.PropHighlight,
			override: true,
		})

		var wininfo = getwininfo(winId)[0]
		var bufnr = winbufnr(winId)
		var lines = float2nr(getwinvar(winId, "&lines") * 0.5)
		_window = popup.Window.new(bufnr, {
			pos: "botleft",
			padding: [1, 1, 1, 1],
			border: [1, 1, 1, 1],
			borderchars: _config.BorderChars,
			borderhighlight: _config.BorderHighlight,
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
		_CreateAutocmd(bufnr)
		SetCursorUnderBuff()
	enddef

	static def _CreateAutocmd(bufnr: number)
		var group = "Quickfix.Previewer"
		var events = [
			{
				bufnr: bufnr,
				group: group,
				event: "CursorMoved",
				cmd: "vim9 quickfix#Previewer.SetCursorUnderBuff()",
			},
			{
				bufnr: bufnr,
				group: group,
				event: ["WinLeave", "WinClosed", "WinLeave", "BufWipeout", "BufHidden"],
				cmd: "vim9 quickfix#Previewer.Close()",
			}
		]

		autocmd_add(events)

		_window.OnClose((_: popup.Window, _: any) => {
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
