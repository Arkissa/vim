vim9script

import 'vim.vim'
import 'window.vim'
import 'buffer.vim'
import 'autocmd.vim'
import 'quickfix.vim'

type Autocmd = autocmd.Autocmd
type Location = quickfix.Location
type Quickfix = quickfix.Quickfix
type Quickfixer = quickfix.Quickfixer
type QuickfixItem = quickfix.QuickfixItem

sign_define([
	{
		name: 'E',
		text: 'E',
		texthl: 'qfError'
	},
	{
		name: 'W',
		text: 'W',
		texthl: 'qfWarn'
	},
	{
		name: 'I',
		text: 'I',
		texthl: 'qfInfo',
	},
	{
		name: 'N',
		text: 'N',
		texthl: 'qfNote',
	},
])

class Text # {{{1
	static const group = 'Quickfixtextfunc'
	static def StripAnsi(text: string): string # {{{2
		return text->substitute('\e\[[0-9;]*m', '', 'g')
	enddef # }}}

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
		var clean = Text.StripAnsi(bufname)
		var len = clean->strdisplaywidth()
		if len <= limit
			return clean
		endif

		return $"…{clean[len - limit + 1 : ]}"
	enddef # }}}

	static def GetText(text: string, limit: number): string # {{{2
		var len = text->strdisplaywidth()
		if len <= limit
			return text
		endif

		return $"{text}…"
	enddef # }}}

	static def Func(info: dict<any>): list<string> # {{{2
		var qf: Quickfixer = info.quickfix == 1
			? Quickfix.new({id: info.id})
			: Location.new(info.winid, {id: info.id})

		var qflist = qf.GetList({id: info.id, items: 1, qfbufnr: 1})
		var qfitems = qflist.items[info.start_idx - 1 : info.end_idx]
		var maxFnameWidth = float2nr(floor(min([95, &columns / 4])))

		var lastwin = window.Window.newByWinnr(winnr('#')->win_getid())
		Autocmd.new('WinClosed')
			.Group(Text.group)
			.Pattern([])
			.Once()
			.Callback(() => {
				sign_unplace(Text.group)
			})
		return qfitems->mapnew((i, item) => {
			var lnum = Text.GetLnum(item)
			var text = item.text
			var fname = ''
			if item.type != quickfix.Type.Empty
				sign_place(0, Text.group, item.type.Value, qflist.qfbufnr, {lnum: info.start_idx + i})
			endif
			if item.valid
				if !filereadable(item.buffer.name)
					text = [item.buffer.name, lnum, text]
						->filter((_, v) => !v->empty())
						->join(':')
					fname = ''
					lnum = ''
				elseif item.buffer.bufnr > 0
					fname = Text.GetFname(fnamemodify(item.buffer.name, ":~:."), maxFnameWidth)
				endif
			endif

			# Build line with conditional spacing
			var parts = [fname, lnum, text]->filter((_, v) => !v->empty())
			var line = parts->join(' ')
			return line
		})
	enddef # }}}
endclass # }}}

export const Func = Text.Func
