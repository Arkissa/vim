vim9script

import 'keymap.vim'
import 'window.vim'

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
	var [lnum, col] = win.GetCursorPos()
	var buf = win.GetBuffer()
	var line = buf.GetOneLine(lnum)

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

	bind.Callback(opening, (): string => {
		return $"{opening}{closing}\<Left>"
	})
endfor
