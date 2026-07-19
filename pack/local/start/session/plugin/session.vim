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

		if exists_compiled('+shellslash')
			def Recover(saved: any)
				&shellslash = saved
			enddef

			defer Recover(&shellslash)
			&shellslash = true
		endif

		var dir = get(g:, "session_dir", "")
		var sessionName = substitute(getcwd(), '\v(^[A-Z]):', '\1@', '')->substitute('/', '@', 'g')

		session.Session.Save(dir, sessionName, attr.mods.silent)
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

		if exists_compiled('+shellslash')
			def Recover(saved: any)
				&shellslash = saved
			enddef

			defer Recover(&shellslash)
			&shellslash = true
		endif

		var dir = get(g:, "session_dir", "")
		var sname = attr.args ?? getcwd()

		sname = sname->substitute('\v(^[A-Z]):', '\1@', '')->substitute('/', '@', 'g')
		session.Session.Load(dir, sname, attr.mods.silent)
	})


Autocmd.new('VimLeavePre')
	.When((): bool => exists('g:session_auto_save'))
	.Group(group)
	.Once()
	.Command('if !bufname()->empty() | silent SessionSave | endif')

Autocmd.new('VimEnter')
	.When((): bool => exists('g:session_auto_load'))
	.Group(group)
	.Once()
	.Command('if argc() == 0 && v:argv->len() == 1 | silent SessionLoad | endif')
