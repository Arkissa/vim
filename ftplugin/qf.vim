vim9script

if exists('b:did_ftplugin')
	finish
endif

b:did_ftplugin = 1
b:undo_ftplugin = 'setlocal list< wrap< bufhidden< buflisted< relativenumber<'

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
	.Map('u', Bind.Cmd('colder'))
	.Map('<C-r>', Bind.Cmd('cnewer'))
	.Callback('K', qfpreview.Toggle)
