vim9script

import autoload 'keymap.vim'
import autoload 'quickfix.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods

:setlocal nolist
:setlocal nowrap
:setlocal nobuflisted
:setlocal norelativenumber

Bind.new(Mods.n)
	.NoRemap()
	.Buffer()
	.Silent()
	.Map('u', '<CMD>colder<CR>')
	.Map('<C-r>', '<CMD>cnewer<CR>')
	.ScriptCmd('K', quickfix.Previewer.Toggle)
