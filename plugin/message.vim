vim9script

import 'keymap.vim'
import 'autocmd.vim'

import autoload 'message.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Message = message.Message
type Autocmd = autocmd.Autocmd

Bind.new(Mods.n)
	.NoWait()
	.NoRemap()
	.Callback(':', Message.new().Callback)

Bind.new(Mods.n)
	.NoWait()
	.NoRemap()
	.Map('<C-w>:', ":")
