vim9script

import autoload 'greps/cgrep.vim'
import autoload 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.Map('[l', '<CMD>lprevious<CR>')
	.Map(']l', '<CMD>lnext<CR>')
	.Map('[q', '<CMD>cprevious<CR>')
	.Map(']q', '<CMD>cnext<CR>')
	.Map('<C-l>', '<CMD>nohlsearch<CR>')

Bind.new(Mods.n)
	.NoWait()
	.Map('gp', '<CMD>put "<CR>')
	.Map('gP', '<CMD>-1put "<CR>')
	.Map('[P', 'i ')
	.Map(']P', 'a ')

Bind.new(Mods.t)
	.Map('', '<C-\><C-n>')

Bind.new(Mods.n)
	.NoRemap()
	.Silent()
	.ScriptCmd('<C-s>', () => {
		echom "hello"
	})
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

Bind.new(Mods.c)
	.NoWait()
	.ScriptCmd('<C-k>', () => {
		setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1))
	})

Bind.newMulti(Mods.i, Mods.v)
	.Silent()
	.NoWait()
	.Map('<C-c>', '"+y')
	.Map('<C-v>', '<C-r>+')

Bind.newMulti(Mods.i, Mods.c)
	.NoWait()
	.Map('<C-a>', '<HOME>')
	.Map('<C-f>', '<Right>')
	.Map('<C-b>', '<Left>')
	.Map('<M-b>', '<C-Left>')
	.Map('<M-f>', '<C-Right>')
