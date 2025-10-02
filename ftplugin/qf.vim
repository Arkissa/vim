vim9script

import '../autoload/qfpreview.vim'

import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

&l:list = false
&l:wrap = false
&l:buflisted = false
&l:relativenumber = false

Bind.new(Mods.n)
	.NoRemap()
	.Buffer()
	.Silent()
	.Map('u', '<CMD>colder<CR>')
	.Map('<C-r>', '<CMD>cnewer<CR>')
	.ScriptCmd('K', qfpreview.Toggle)
