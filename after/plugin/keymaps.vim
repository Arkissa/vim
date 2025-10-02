vim9script

import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

Bind.new(Mods.n)
	.Silent()
	.NoRemap()
	.When(() => exists('*g:FugitiveStatusline'))
	.Map('gb', '<CMD>Git blame --date=short<CR>')
	.Map('<Leader>g', '<CMD>:vertical Git<CR>')
	.Map('<Leader>d', '<CMD>:Gvdiffsplit!<CR>')
	.Map('<Leader>o', '<CMD>only<CR>')
