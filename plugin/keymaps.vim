vim9script

import autoload 'greps/cgrep.vim'
import autoload 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.LHS('[l').RHS('<CMD>lprevious<CR>')
	.LHS(']l').RHS('<CMD>lnext<CR>')
	.LHS('[q').RHS('<CMD>cprevious<CR>')
	.LHS(']q').RHS('<CMD>cnext<CR>')
	.LHS('<C-l>').RHS('<CMD>nohlsearch<CR>')
	.Done()

Bind.new(Mods.n)
	.NoWait()
	.LHS('gp').RHS('<CMD>put "<CR>')
	.LHS('gP').RHS('<CMD>-1put "<CR>')
	.LHS('[P').RHS('i ')
	.LHS(']P').RHS('a ')
	.Done()

Bind.newMulti(Mods.i, Mods.v)
	.Silent()
	.NoWait()
	.LHS('<C-c>').RHS('"+y')
	.LHS('<C-v>').RHS('<C-r>+')
	.Done()

Bind.newMulti(Mods.i, Mods.c)
	.NoWait()
	.LHS('<C-a>').RHS('<HOME>')
	.LHS('<C-f>').RHS('<Right>')
	.LHS('<C-b>').RHS('<Left>')
	.LHS('<M-b>').RHS('<C-Left>')
	.LHS('<M-f>').RHS('<C-Right>')
	.Done()

Bind.newMulti(Mods.c)
	.NoWait()
	.LHS('<C-k>').RHS('<ScriptCmd>(() => setcmdline(strpart(getcmdline(), 0, getcmdpos() - 1)))()<CR>')
	.Done()

Bind.new(Mods.t)
	.LHS('').RHS('<C-\><C-n>')
	.Done()

Bind.new(Mods.n)
	.NoRemap()
	.Silent()
	.LHS('\\').RHS('@@')
	.LHS('<Leader>[').RHS('<ScriptCmd>appendbufline(bufnr(), line(''.'') - 1, '''')<CR>')
	.LHS('<Leader>]').RHS('<ScriptCmd>appendbufline(bufnr(), line(''.''), '''')<CR>')
	.Done()

Bind.new(Mods.n)
	.By(() => instanceof(g:Grep, cgrep.Cgrep))
	.NoRemap()
	.LHS('\w').RHS(':Grep ')
	.LHS('\s').RHS(':Grep --string ')
	.LHS('\r').RHS(':Grep -G ')
	.Done()
