vim9script

import 'command.vim'
import 'autocmd.vim'
import 'session.vim'

type Command = command.Command
type NArgs = command.NArgs
type Complete = command.Complete
type Autocmd = autocmd.Autocmd

const SimpleSession = get(g:, 'SimpleSession', {})
const group = "Sesssion"

Command.new('SessionSave')
	.Callback((attr) => {
		var dir = get(SimpleSession, "dir", "")
		session.Session.Save(dir, fnamemodify(getcwd(), ':t'), attr.mods.silent)
	})

Command.new('SessionLoad')
	.NArgs(NArgs.Quest)
	.Complete(Complete.CustomList, (_, _, _): list<string> => {
		var dir = get(SimpleSession, "dir", "")
		return session.Session.All(dir)->map((_, name) => {
			return fnamemodify(name, ':p:h:t')
		})
	})
	.Callback((attr) => {
		var dir = get(SimpleSession, "dir", "")
		session.Session.Load(dir, attr.args, attr.mods.silent)
	})


Autocmd.new('VimLeavePre')
	.When((): bool => get(SimpleSession, 'saveOnVimLeave', false))
	.Group(group)
	.Once()
	.Command('silent SessionSave')

Autocmd.new('BufEnter')
	.When((): bool => get(SimpleSession, 'loadOnBufEnter', false))
	.Group(group)
	.Once()
	.Command('silent SessionLoad')
