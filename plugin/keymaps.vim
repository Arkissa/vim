vim9script

import 'keymap.vim'
import 'log.vim'
import 'quickfix.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

def QuickfixRingIdx(locl: bool, prev: bool)
	var qf: quickfix.Quickfixer = locl
		? quickfix.Location.newCurrent()
		: quickfix.Quickfix.newCurrent()

	if qf.Empty()
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

Bind.new(Mods.t)
	.Map('', '<C-\><C-n>')

Bind.new(Mods.n)
	.NoRemap()
	.NoWait()
	.Map('<Leader>f', ':find ./')
	.Map('<Leader>b', ':buffer ')

	.Silent()
	.Map('\\', '@@')

	.Callback('[<Leader>', () => {
		appendbufline(bufnr(), line('.') - 1, '')
	})

	.Callback(']<Leader>', () => {
		appendbufline(bufnr(), line('.'), '')
	})

Bind.new(Mods.c)
	.NoWait()
	.Callback('<C-k>', () => {
		setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1))
	})
	.Callback('<M-d>', () => {
		var line = getcmdline()
		var pos = getcmdpos() - 1
		var start = line->slice(0, pos)
		setcmdline(start .. substitute(line->slice(pos), '^.\{-\}\<\w\+\>', '', ''), pos + 1)
	})
	.Map('<C-d>', '<Del>')

Bind.new(Mods.x)
	.Silent()
	.NoWait()
	.Map('<C-c>', '"+y')

Bind.new(Mods.i)
	.Silent()
	.NoWait()
	.Map('<C-v>', '<C-r>+')

Bind.newMulti(Mods.i, Mods.c)
	.NoWait()
	.Map('<C-a>', '<HOME>')
	.Map('<C-f>', '<Right>')
	.Map('<C-b>', '<Left>')
	.Map('<M-b>', '<C-Left>')
	.Map('<M-f>', '<C-Right>')

Bind.new(Mods.n)
	.Silent()
	.Map('\g', ':vertical leftabove term! ++cols=100 opencode --continue<CR>')
