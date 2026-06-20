vim9script

import 'log.vim'
import 'keymap.vim'
import 'buffer.vim'
import 'quickfix.vim'

type Terminal = buffer.Terminal

type Bind = keymap.Bind
type Mods = keymap.Mods

def QuickfixRingIdx(locl: bool, prev: bool)
	var qf: quickfix.Quickfixer = locl
		? quickfix.Location.newCurrent()
		: quickfix.Quickfix.newCurrent()

	if qf.IsEmpty()
		log.Error('E553: No more items')
		return
	endif

	var idx = prev
		? qf.PrevValidIdx(true)
		: qf.NextValidIdx(true)

	qf.Jump(idx)
	var what = qf.GetList({idx: idx, size: 1, items: 1})

	var item = what.items[0]
	if !item.valid
		return
	endif

	var type: string
	if item.type == quickfix.Type.E
		type = ' error:'
	elseif item.type == quickfix.Type.W
		type = ' warning:'
	elseif item.type == quickfix.Type.I
		type = ' info:'
	elseif item.type == quickfix.Type.N
		type = ' hint:'
	else
		type = ''
	endif

	:redraw
	echo $'({idx} of {what.size}){type} {item.text}'
enddef

Bind.new(Mods.n)
	.Silent()
	.NoWait()
	.Map('gp', Bind.Cmd('put "'))
	.Map('gP', Bind.Cmd('-1put "'))
	.Map('[P', 'i ')
	.Map(']P', 'a ')
	.Callback('[l', funcref(QuickfixRingIdx, [true, true]))
	.Callback(']l', funcref(QuickfixRingIdx, [true, false]))
	.Callback('[q', funcref(QuickfixRingIdx, [false, true]))
	.Callback(']q', funcref(QuickfixRingIdx, [false, false]))

Bind.new(Mods.n)
	.NoRemap()
	.NoWait()
	.Map('<Leader>f', ':find ')
	.Map('<Leader>b', ':buffer ')

	.Silent()
	.Map('\\', '@@')

	.Callback('[<Leader>', () => {
		appendbufline(bufnr(), line('.') - 1, '')
	})

	.Callback(']<Leader>', () => {
		appendbufline(bufnr(), line('.'), '')
	})

Bind.new(Mods.t)
	.NoWait()
	.Map('<M-d>', '<ESC>d')

Bind.new(Mods.x)
	.Silent()
	.NoWait()
	.Map('<C-c>', '"+y')

Bind.new(Mods.i)
	.Silent()
	.NoWait()
	.Map('<C-S-v>', paste#paste_cmd['i'])

Bind.newMulti(Mods.i, Mods.c, Mods.t)
	.NoWait()
	.Map('<C-a>', '<HOME>')
	.Map('<C-f>', '<Right>')
	.Map('<C-b>', '<Left>')
	.Map('<M-b>', '<C-Left>')
	.Map('<M-f>', '<C-Right>')

var cmdlineYank = ""

Bind.new(Mods.c)
	.NoRemap()
	.NoWait()
	.Expr()
	.Callback('<C-u>', () => {
		var line = getcmdline()
		var pos = getcmdpos() - 1

		cmdlineYank = line->strcharpart(0, pos)

		return "\<C-u>"
	})
	.Callback('<C-w>', () => {
		var line = getcmdline()
		var pos = getcmdpos() - 1
		var text = line->strcharpart(0, pos)->matchstr('\v<\w+>$')
		cmdlineYank = text

		return "\<C-w>"
	})

Bind.new(Mods.c)
	.NoWait()
	.Callback('<C-k>', () => {
		var line = getcmdline()
		var pos = getcmdpos() - 1

		var n = line->strdisplaywidth() - pos
		cmdlineYank = line->strcharpart(pos, n)
		var text = line->strcharpart(0, pos)

		setcmdline(text)
	})
	.Callback('<M-d>', () => {
		const wordRegexp = '^.\{-\}\<\w\+\>'
		var line = getcmdline()
		var pos = getcmdpos() - 1
		var start = line->slice(0, pos)
		var text = line->slice(pos)

		cmdlineYank = matchstr(text, wordRegexp)
		setcmdline(start .. substitute(text, wordRegexp, '', ''), pos + 1)
	})
	.Map('<C-d>', '<Del>')
	.Expr()
	.Callback('<C-y>', () => {
		if pumvisible()
			return "\<C-y>"
		endif
		var line = getcmdline()
		var pos = getcmdpos() - 1
		var start = line->slice(0, pos)
		if cmdlineYank == ""
			return ''
		endif

		setcmdline(start .. cmdlineYank .. line->slice(pos), pos + len(cmdlineYank) + 1)
		return ''
	})

Bind.new(Mods.n)
	.NoRemap()
	.NoWait()
	.Callback("'\<CR>", () => {
		var cmd = expandcmd(input('Command Shell: ', '', 'shellcmdline'))
		histadd(':', $"terminal {cmd}")
		Terminal.new(cmd ?? $SHELL, {hidden: false})
	})
