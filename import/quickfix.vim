vim9script

import 'buffer.vim'
import 'window.vim'

type Buffer = buffer.Buffer

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
	var buffer: Buffer
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
	def SetList(entry: list<QuickfixItem>, action: Action, what: dict<any> = null_dict): bool
	def GetList(what: dict<any> = null_dict): any
	def GetItemUnderTheCursor(): QuickfixItem
	def Jump(nr: number = 1)
	def Open(height: number = 0)
	def Close()
	def Window(height: number = 0)
	def IsLocation(): bool
	def Empty(): bool
	def IsOpen(): bool
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
			return setqflist(items, action.Value) == 0
		endif

		if !what->has_key('id')
			what.id = this.id
		endif

		return setqflist(items, action.Value, what) == 0
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

		var b = Buffer.newCurrent()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def Jump(nr: number = 1)
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

	def IsOpen(): bool
		var items = this.GetList({id: this.id, winid: 1})
		if items->empty()
			return false
		endif

		return window.Window.newByWinnr(items.winid).IsOpen()
	enddef
endclass

export class Location implements Quickfixer
	var id: number
	var winnr: number

	def new(winnr: number, what: dict<any> = null_dict)
		if what == null_dict
			setloclist(this.winnr, [], ' ')
			var item = getloclist(winnr, {all: 1})
			this.winnr = item.winid
			this.id = item.id
		else
			this.id = what.id
		endif
	enddef

	def newCurrent()
		this.id = getloclist(win_getid(), {all: 1}).id
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

		var b = Buffer.newCurrent()
		var item = this.GetList({idx: b.GetLinePosition(), items: 1}).items[0]
		if !item.valid || item.buffer.IsDirectory() || !item.buffer.Readable()
			return null_object
		endif

		return item
	enddef

	def Jump(nr: number = 1)
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

	def IsOpen(): bool
		return window.Window.newByWinnr(this.winnr).IsOpen()
	enddef
endclass
