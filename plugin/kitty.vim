vim9script

if get(g:, 'disable_kitty_navigator', false) || empty($KITTY_LISTEN_ON)
	finish
endif

import 'keymap.vim'
import 'autocmd.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

const kitty_direction = {
	j: 'bottom',
	k: 'top',
	h: 'left',
	l: 'right',
}

const group = 'KittyNavigator'
const IN_VIM = 'IN_VIM'
const VIM_SERVERNAME = 'VIM_SERVERNAME'
const VIM_MODE = 'VIM_MODE'
const VIM_EQUALWIN = 'VIM_EQUALWIN'

def KittyCommand(name: string, ...args: list<string>): string
	var cmd = ['kitten', '@', name] + args

	if exists('g:kitty_navigator_password')
		cmd->add($'--password=' .. g:kitty_navigator_password->string())
	endif

	return system(cmd)
enddef

def SetKittyVars(...vars: list<tuple<string, any>>)
	call(KittyCommand, ["set-user-vars"] + vars->mapnew((_, var) => $'{var[0]}={type(var[1]) == v:t_string ? var[1] : var[1]->string()}'))
enddef

def DeleteKittyVars(...varnames: list<string>)
	call(KittyCommand, ["set-user-vars"] + varnames->mapnew((_, varname) => $'{varname}'))
enddef

def KittyNavigator(direction: string)
	KittyCommand('focus-window', '--match', $'neighbor:{direction}')
enddef

def Navigator(direction: string)
	var current = win_getid()
	var target = win_getid(winnr(direction))

	if current != target
		win_gotoid(target)
	else
		KittyNavigator(kitty_direction[direction])
	endif
enddef

Autocmd.newMulti(['VimEnter', 'VimResume'])
	.Group(group)
	.Callback(() => {
		SetKittyVars(
			(IN_VIM, true),
			(VIM_SERVERNAME, v:servername),
			(VIM_MODE, mode()),
			(VIM_EQUALWIN, get(g:, 'kitty_equalwin', 0)),
		)
	})

Autocmd.newMulti(['VimLeavePre', 'VimSuspend'])
	.Group(group)
	.Callback(() => {
		DeleteKittyVars(IN_VIM, VIM_SERVERNAME, VIM_MODE)
	})

Autocmd.new('ModeChanged')
	.Group(group)
	.Callback(() => {
		SetKittyVars((VIM_MODE, v:event.new_mode))
	})

Bind.newMulti(Mods.n, Mods.t)
	.Callback('<C-w>j', () => Navigator('j'))
	.Callback('<C-w>k', () => Navigator('k'))
	.Callback('<C-w>h', () => Navigator('h'))
	.Callback('<C-w>l', () => Navigator('l'))
