vim9script

import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.NoRemap()
	.When(() => exists('*g:FugitiveStatusline'))
	.Map('gb', Bind.Cmd('Git blame --date=short'))
	.Map('<Leader>g', Bind.Cmd(':vertical Git'))
	.Map('<Leader>d', Bind.Cmd(':Gvdiffsplit!'))
	.Map('<Leader>o', Bind.Cmd('only'))
