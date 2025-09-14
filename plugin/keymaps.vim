vim9script

import '../autoload/keymap.vim'
import '../autoload/plugin/greps/cgrep.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.NoWait()
	.Map('gp', '<CMD>put "<CR>')
	.Map('gP', '<CMD>-1put "<CR>')
	.Map('[P', 'i ')
	.Map(']P', 'a ')
	.Map('[l', '<CMD>lprevious<CR>')
	.Map(']l', '<CMD>lnext<CR>')
	.Map('[q', '<CMD>cprevious<CR>')
	.Map(']q', '<CMD>cnext<CR>')
	.Map('<C-l>', '<CMD>nohlsearch<CR>')

Bind.new(Mods.t)
	.Map('', '<C-\><C-n>')

Bind.new(Mods.n)
	.NoRemap()
	.Map('<Leader>f', ':find **/')

	.Silent()
	.Map('\\', '@@')

	.ScriptCmd('<Leader>[', () => {
		appendbufline(bufnr(), line('.') - 1, '')
	})

	.ScriptCmd('<Leader>]', () => {
		appendbufline(bufnr(), line('.'), '')
	})

Bind.new(Mods.n)
	.When(() => instanceof(g:Grep, cgrep.Cgrep))
	.NoRemap()
	.Map('\w', ':Grep ')
	.Map('\s', ':Grep --string ')
	.Map('\r', ':Grep -G ')
	.Map('\d', ':Grep --name <C-r><C-w>')

Bind.new(Mods.c)
	.NoWait()
	.ScriptCmd('<C-k>', () => {
		setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1))
	})
	.ScriptCmd('<M-d>', () => {
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
