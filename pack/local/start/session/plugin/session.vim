vim9script

import 'command.vim'
import 'autocmd.vim'
import autoload 'session/session.vim'

type NArgs = command.NArgs
type Autocmd = autocmd.Autocmd
type Command = command.Command
type Complete = command.Complete

const group = "Session"

def IsTemp(): bool
	if exists_compiled('+shellslash')
		def Recover(saved: any)
			&shellslash = saved
		enddef

		defer Recover(&shellslash)
		&shellslash = true
	endif

	var dir = expand('%:p:h')
	return dir =~# '\(^/\|^[A-Z]:/\)tmp'
enddef

Command.new('SessionSave')
	.Bar()
	.Callback((attr) => {
		if IsTemp()
			return
		endif

		var dir = get(g:, "session_dir", "")
		session.Session.Save(dir, fnamemodify(getcwd(), ':t'), attr.mods.silent)
	})

Command.new('SessionLoad')
	.NArgs(NArgs.Quest)
	.Bar()
	.Complete(Complete.CustomList, (_, _, _): list<string> => {
		var dir = get(g:, "session_dir", "")
		return session.Session.All(dir)->map((_, name) => {
			return fnamemodify(name, ':p:h:t')
		})
	})
	.Callback((attr) => {
		if IsTemp()
			return
		endif

		var dir = get(g:, "session_dir", "")
		session.Session.Load(dir, attr.args, attr.mods.silent)
	})


Autocmd.new('VimLeavePre')
	.When((): bool => exists('g:session_auto_save'))
	.Group(group)
	.Once()
	.Command('silent SessionSave')

Autocmd.new('VimEnter')
	.When((): bool => exists('g:session_auto_load'))
	.Group(group)
	.Once()
	.Command('if argc() == 0 | SessionLoad | endif')
