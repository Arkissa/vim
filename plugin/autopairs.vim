vim9script

import 'keymap.vim'
import 'window.vim'
import 'vim.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Window = window.Window

var pairs = get(g:, 'AutoPairs', {
	['(']: ')',
	['[']: ']',
	['{']: '}',
	['<']: '>',
	["'"]: "'",
	['"']: '"',
	['`']: '`',
})

def Del(): string
	var win = Window.newCurrent()
	var pos: tuple<number, number> = win.GetCursorPos()
	var [lnum, col] = pos
	var line = win.GetBuffer().GetOneLine(lnum)

	var opening = line[col - 2]
	var closing = line[col - 1]
	if !has_key(pairs, opening)
		return $"\<BS>"
	endif

	return pairs[opening] == closing
		? $"\<BS>\<Del>"
		: $"\<BS>"
enddef

var bind = Bind.new(Mods.i)
	.NoRemap()
	.Expr()
	.Callback("\<BS>", Del)
	.Callback("", Del)

for [open, close] in pairs->items()
	var opening = open
	var closing = close

	if opening == closing
		bind.Callback(opening, (): string => {
			var win = Window.newCurrent()
			var pos: tuple<number, number> = win.GetCursorPos()
			var [lnum, col] = pos
			var line = win.GetBuffer().GetOneLine(lnum)

			if line[col - 1] == closing
				return "\<Right>"
			endif

			return $"{opening}{closing}\<Left>"
		})
	else
		bind.Callback(opening, (): string => {
			return $"{opening}{closing}\<Left>"
		})

		bind.Callback(closing, (): string => {
			var win = Window.newCurrent()
			var pos: tuple<number, number> = win.GetCursorPos()
			var [lnum, col] = pos
			var line = win.GetBuffer().GetOneLine(lnum)

			if line[col - 1] == closing
				return "\<Right>"
			endif

			return closing
		})
	endif
endfor
