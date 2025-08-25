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
	def GetList(what: dict<any>): list<dict<any>>
	def JumpFirst(bufnr: number)
	def Open(height: number)
	def Close()
	def Window(height: number)
	def IsLocation(): bool
endinterface

export class Quickfix implements Quickfixer
	def SetList(entry: list<dict<any>>, action: Action, what: dict<any> = {}): bool
		if !what->empty()
			return setqflist(entry, action.Value, what) == 0
		endif

		return setqflist(entry, action.Value) == 0
	enddef

	def GetList(what: dict<any>): list<dict<any>>
		return getqflist(what)
	enddef

	def JumpFirst(bufnr: number)
		:silent cc bufnr
	enddef

	def Open(height: number)
		:copen height
	enddef

	def Close()
		:cclose
	enddef

	def Window(height: number)
		:cwindow height
	enddef

	def IsLocation(): bool
		return false
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

	def GetList(what: dict<any>): list<dict<any>>
		return getloclist(this.winnr, what)
	enddef

	def JumpFirst(bufnr: number)
		:silent ll bufnr
	enddef

	def Open(height: number)
		:lopen height
	enddef

	def Close()
		:lclose
	enddef

	def Window(height: number)
		:lwindow height
	enddef

	def IsLocation(): bool
		return true
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
	static var _prop_id: number = -1
	static var _qf: Quickfixer = v:none
	static var _window: popup.Window

	static def Open()
		var winnr = winnr()
		if getwinvar(winnr, "quickfix") == 0
			return
		endif

		var bufnr = getwinvar(winnr, "bufnr")
		_CreateAutocmd(bufnr)

		_qf = getwinvar(winnr, "loclist") == 1
			? Location.new(winnr)
			: Quickfix.new()

		# TODO open popup and autocmd.
		_window = popup.Window.new(bufnr, {
			pos: "botleft",
			border: [],
			maxheight: 1,
			minwidth: 1,
			maxwidth: 1,
			col: 1,
			line: 1,
		})

		_SetCursorUnderBuff()
	enddef

	static def _CreateAutocmd(bufnr: number)
		var group = "Previewer"
		var autocmd = [
			_CursorMoved(group, bufnr),
			_QuickfixLeave(group, bufnr),
		]

		autocmd_add(autocmd)

		_window.OnClose((_, _) => autocmd_delete(autocmd))
	enddef

	static def _SetCursorUnderBuff()
		var items = _qf.GetList({})
		if items->len() == 0
			return
		endif

		var item = items[line('.') - 1]
		if item.valid != 1
			return
		endif

		_window.SetBuf(item.bufnr)
		_window.SetTitle($" [{item.lnum}/{line('$')}] buf {item.bufnr}: {fnamemodify(bufname(bufnr), ":~:.")} {getbufvar(item.bufnr, "modified") == 1 ? "[+]" : ""}")
		_window.SetCursor(item.lnum, item.col)
		_window.FeedKeys("zz")
	enddef

	static def _CursorMoved(group: string, bufnr: number): dict<any>
		return {
				group: group,
				bufnr: bufnr,
				event: "CursorMoved",
				cmd: 'call _SetCursorUnderBuff()',
			}
	enddef

	static def _QuickfixLeave(group: string, bufnr: number)
		return {
			group: group,
			bufnr: bufnr,
			event: ["WinLeave", "WinClosed", "WinLeave", "BufWipeout", "BufHidden"],
			cmd: 'call Close()'
		}
	enddef

	static def Toggle()
		if this._window.IsOpen()
			Close()
		else
			Open()
		endif
	enddef

	static def Close()
		if _IsOpen()
			_window.Close()
			_qf = v:none
		endif
	enddef
endclass
