vim9script

import 'quickfix.vim'

type Location = quickfix.Location
type Quickfix = quickfix.Quickfix
type Quickfixer = quickfix.Quickfixer
type QuickfixItem = quickfix.QuickfixItem

class Text # {{{1
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
	enddef # }}}

	static def GetFname(bufname: string, limit: number): string # {{{2
		var len = bufname->strdisplaywidth()
		if len <= limit
			return bufname
		endif

		return $"…{bufname[len - limit + 1 : ]}"
	enddef # }}}

	static def Func(info: dict<any>): list<string> # {{{2
		var qf: Quickfixer = info.quickfix == 1 ? Quickfix.new({id: info.id}) : Location.new(info.winid, {id: info.id})

		var qflist = qf.GetList({id: info.id, items: 1})
		var qfitems = qflist.items[info.start_idx - 1 : info.end_idx]
		var maxFnameWidth = float2nr(floor(min([95, &columns / 4])))
		var max_row = qfitems
			->mapnew((_, item) => Text.GetLnum(item))
			->map((_, row) => row->strdisplaywidth())
			->max()
		var max_type = qfitems
			->mapnew((_, item) => item.type.Value->strdisplaywidth())
			->max()
		max_type = max_type == 0 ? 0 : max_type + 1
		b:quickfix_max_type = max((get(b:, 'quickfix_max_type', max_type), max_type))
		b:quickfix_max_row = max((get(b:, 'quickfix_max_type', max_row), max_row))

		return qfitems->mapnew((_, item) => {
				var fname = ''
				var lnum = ''
				var text = item.text
				var row = b:quickfix_max_row
				var type = b:quickfix_max_type
				if item.valid
					if filereadable(item.buffer.name)
						fname = Text.GetFname(fnamemodify(item.buffer.name, ":~:."), maxFnameWidth)
						lnum = Text.GetLnum(item)
					elseif item.buffer.IsExists()
						text = $'{item.buffer.name}{lnum}{text}'
						item.buffer.Delete()
						row = 0
					endif
				endif

				var line = $"%-{type}s%-{maxFnameWidth}s │%{row}s│%{min([99, item.text->strdisplaywidth() + 1])}s"
				return printf(line, item.type.Value, fname, lnum, text)
			})
	enddef # }}}
endclass # }}}

export const Func = Text.Func
