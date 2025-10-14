vim9script

import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.NoWait()
	.Map('gp', Bind.Cmd('put "'))
	.Map('gP', Bind.Cmd('-1put "'))
	.Map('[P', 'i ')
	.Map(']P', 'a ')
	.Map('[l', Bind.Cmd('lprevious'))
	.Map(']l', Bind.Cmd('lnext'))
	.Map('[q', Bind.Cmd('cprevious'))
	.Map(']q', Bind.Cmd('cnext'))
	.Map('<C-l>', Bind.Cmd('nohlsearch'))

Bind.new(Mods.t)
	.Map('', '<C-\><C-n>')

Bind.new(Mods.n)
	.NoRemap()
	.NoWait()
	.Map('<Leader>f', ':find ./')
	.Map('<Leader>b', ':buffer ')

	.Silent()
	.Map('\\', '@@')

	.Callback('<Leader>[', () => {
		appendbufline(bufnr(), line('.') - 1, '')
	})

	.Callback('<Leader>]', () => {
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
