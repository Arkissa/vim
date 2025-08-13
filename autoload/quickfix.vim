vim9script

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
		return getqflist(what)->map((_, entry) => this._to_entry(entry))
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
		return getloclist(this.winnr, what)->map((_, entry) => this._to_entry(entry))
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

	return "…" .. bufname[len - limit + 1 : ]
enddef

export def QuickfixTextFunc(info: dict<any>): list<string>
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
