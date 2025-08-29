vim9script

import "./popup.vim"

export enum Action
	A("a"),
	R("r"),
	U("u"),
	F("f")

	var Value: string
endenum

export interface Quickfixer
	def SetList(entry: list<dict<any>>, action: Action, what: dict<any>): bool
	def GetList(what: dict<any> = null_dict): any
	def GetItemUnderTheCursor(): dict<any>
	def JumpFirst(bufnr: number)
	def Open(height: number = 0)
	def Close()
	def Window(height: number = 0)
	def IsLocation(): bool
	def Empty(): bool
endinterface

export class Quickfix implements Quickfixer
	def SetList(entry: list<dict<any>>, action: Action, what: dict<any> = {}): bool
		if !what->empty()
			return setqflist(entry, action.Value, what) == 0
		endif

		return setqflist(entry, action.Value) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any
		if what == null_dict
			return getqflist()
		endif

		return getqflist(what)
	enddef

	def GetItemUnderTheCursor(): dict<any>
		if this.Empty()
			return null_dict
		endif

		var item = this.GetList()[line('.') - 1]
		if item.valid != 1 || bufname(item.bufnr)->isdirectory()
			return null_dict
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
		var items = this.GetList()
		return items is null_list || items is null_dict
	enddef
endclass

export class Location implements Quickfixer
	var winnr: number

	def new(this.winnr)
	enddef

	def SetList(entry: list<dict<any>>, action: Action, what: dict<any> = {}): bool
		if !what->empty()
			return setloclist(this.winnr, entry, action.Value, what) == 0
		endif

		return setloclist(this.winnr, entry, action.Value) == 0
	enddef

	def GetList(what: dict<any> = null_dict): any
		if what is null_dict
			return getloclist()
		endif

		return getloclist(this.winnr, what)
	enddef

	def GetItemUnderTheCursor(): dict<any>
		if this.Empty()
			return null_dict
		endif

		var item = this.GetList()[line('.') - 1]
		if item.valid != 1
			return null_dict
		endif

		return item
	enddef

	def JumpFirst(bufnr: number)
		:silent ll bufnr
	enddef

	def Open(height: number = 0)
		if height != 0
			:lopen height
		else
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
		var items = this.GetList()
		return items is null_list || items is null_dict
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
	static var _prop_name: string = "quickfix.Previewer"
	static var _qf: Quickfixer
	static var _window: popup.Window
	public static var Config: dict<any> = {
		BorderHighlight: ["Title", "Title", "Title", "Title"],
		BorderChars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
		PropHighlight: "Cursor",
		Number: true,
		CursorLine: true,
	}

	static def _Filter(win: popup.Window, key: string): bool
		if index(["\<C-u>", "\<C-d>", "G", "gg"], key) != -1
			win.FeedKeys(key, "mx")
			return true
		endif

		return false
	enddef

	static def _WinOption(win: popup.Window)
		if Config.Number
			win.SetVar("&number", 1)
		endif

		if Config.CursorLine
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
		if item == null_dict
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

		if _qf.Empty() || _qf.GetItemUnderTheCursor() is null_dict
			return
		endif

		prop_type_add(_prop_name, {
			highlight: Config.PropHighlight,
			override: true,
		})

		var wininfo = getwininfo(winId)[0]
		var bufnr = winbufnr(winId)
		var lines = float2nr(getwinvar(winId, "&lines") * 0.5)
		_window = popup.Window.new(bufnr, {
			pos: "botleft",
			padding: [1, 1, 1, 1],
			border: [1, 1, 1, 1],
			borderchars: Config.BorderChars,
			borderhighlight: Config.BorderHighlight,
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
		:execute $"augroup Quickfix.Previewer_{bufnr}"
			:autocmd CursorMoved <buffer> quickfix#Previewer.SetCursorUnderBuff()
			:autocmd WinLeave,WinClosed,WinLeave,BufWipeout,BufHidden <buffer> quickfix#Previewer.Close()
		:augroup END

		_window.OnClose((_: popup.Window, _: any) => {
			:execute $"augroup Quickfix.Previewer_{bufnr}"
				:autocmd!
			:augroup END
		})
	enddef

	static def SetCursorUnderBuff()
		if _window is null_object || _qf is null_object
			return
		endif

		var item = _qf.GetItemUnderTheCursor()
		if item is null_dict
			return
		endif

		_window.SetBuf(item.bufnr)
		var bufinfo = getbufinfo(item.bufnr)[0]
		_window.SetTitle($" [{item.lnum}/{bufinfo.linecount}] buffer {item.bufnr}: {fnamemodify(bufinfo.name, ":~:.")} {bufinfo.changed == 1 ? "[+]" : ""}")
		_window.SetCursor(item.lnum, item.col)
		_window.FeedKeys("z.", "mx")
	enddef

	static def Toggle()
		if _window isnot null_object && _window.IsOpen()
			Close()
		else
			Open()
		endif
	enddef

	static def Close()
		if _window isnot null_object && _window.IsOpen()
			_window.Close()
		endif
	enddef
endclass
