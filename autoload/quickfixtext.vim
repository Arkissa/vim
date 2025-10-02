vim9script

import 'quickfix.vim'

type Location = quickfix.Location
type Quickfix = quickfix.Quickfix
type Quickfixer = quickfix.Quickfixer
type QuickfixItem = quickfix.QuickfixItem

class Text
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

export const Func = Text.Func
