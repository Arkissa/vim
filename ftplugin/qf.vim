vim9script

import '../autoload/qfpreview.vim'

import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

&l:list = false
&l:wrap = false
&l:buflisted = false
&l:relativenumber = false
&l:winfixbuf = true
&l:signcolumn = 'auto'
&l:numberwidth = 2

Bind.new(Mods.n)
	.NoRemap()
	.Buffer()
	.Silent()
	.Map('u', Bind.Cmd('colder'))
	.Map('<C-r>', Bind.Cmd('cnewer'))
	.Callback('K', qfpreview.Toggle)
