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
		this.type = Type.FromString(get(item, 'type', ''))
		this.vcol = get(item, 'vcol', 0)
		this.module = get(item, 'module', '')
		this.user_data = get(item, 'user_data', null_dict)
		this.pattern = get(item, 'pattern', '')
		this.nr = get(item, 'nr', 0)
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
	def IsEmpty(): bool
	def IsOpen(): bool
	def GetItemsWithType(): list<QuickfixItem>
	def NextValidIdx(ring: bool): number
	def PrevValidIdx(ring: bool): number
endinterface

def NextIdx(qf: Quickfixer, id: number, ring: bool, prev: bool): number
	var what = qf.GetList({id: id, items: 1, idx: 0, size: 1})
	var size = what.size

	if size == 0
		return 0
	endif

	def IsValid(_: number, d: tuple<number, QuickfixItem>): bool
		var item = d[1]

		return item.valid && item.buffer.Readable()
	enddef

	var items: any = what.items
		->map((i, item) => (i, item))
		->filter(IsValid)

	if items->empty()
		return 0
	endif

	def Ok(i: number, idx: number): bool
		if prev
			return i < idx
		else
			return i > idx
		endif
	enddef

	if prev
		items = reverse(items)
	endif

	var idx = what.idx
	for [i, item] in items
		if Ok(i + 1, idx)
			return i + 1
		endif
	endfor

	return ring ? items[0][0] + 1 : idx
enddef

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

	def GetItemsWithType(): list<QuickfixItem>
		return this.GetList({id: this.id, items: 1})->filter((_, item) => item.type != Type.Empty)
	enddef

	def GetItemUnderTheCursor(): QuickfixItem
		if this.IsEmpty()
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
		execute($'silent! cc {nr}')
	enddef

	def Open(height: number = 0)
		var cmd = 'copen'
		if height > 0
			cmd ..=  $' {height}'
		endif

		execute(cmd)
	enddef

	def Close()
		:cclose
	enddef

	def Window(height: number = 0)
		var cmd = 'cwindow'
		if height > 0
			cmd ..=  $' {height}'
		endif

		execute(cmd)
	enddef

	def IsLocation(): bool
		return false
	enddef

	def IsEmpty(): bool
		return this.GetList() == null_list
	enddef

	def IsOpen(): bool
		var items = this.GetList({id: this.id, winid: 1})
		if items->empty()
			return false
		endif

		return window.Window.newByWinnr(items.winid).IsOpen()
	enddef

	def NextValidIdx(ring: bool): number
		return NextIdx(this, this.id, ring, false)
	enddef

	def PrevValidIdx(ring: bool): number
		return NextIdx(this, this.id, ring, true)
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
		if this.IsEmpty()
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
		execute($'silent! ll {nr}')
	enddef

	def Open(height: number = 0)
		var cmd = 'lopen'
		if height > 0
			cmd ..=  $' {height}'
		endif

		execute(cmd)
	enddef

	def Close()
		execute('lclose')
	enddef

	def Window(height: number = 0)
		var cmd = 'lwindow'
		if height > 0
			cmd ..=  $' {height}'
		endif

		execute(cmd)
	enddef

	def IsLocation(): bool
		return true
	enddef

	def IsEmpty(): bool
		return this.GetList() == null_list
	enddef

	def IsOpen(): bool
		return window.Window.newByWinnr(this.winnr).IsOpen()
	enddef

	def GetItemsWithType(): list<QuickfixItem>
		return this.GetList({id: this.id, items: 1}).items->filter((_, item) => item.type != Type.Empty)
	enddef

	def NextValidIdx(ring: bool): number
		return NextIdx(this, this.id, ring, false)
	enddef

	def PrevValidIdx(ring: bool): number
		return NextIdx(this, this.id, ring, true)
	enddef
endclass
