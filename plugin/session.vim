vim9script

import autoload 'command.vim'
import autoload 'session.vim'

const SimpleSession = get(g:, 'SimpleSession', {})

command.Command.new('SessionSave')
	.Callback((attr) => {
		var dir = get(SimpleSession, "dir", "")
		session.Session.Save(dir, fnamemodify(getcwd(), ':t'), attr.mods.silent)
	})

command.Command.new('SessionLoad')
	.NArgs(command.NArgs.Quest)
	.Complete(command.Complete.CustomList, (_, _, _): list<string> => {
		var dir = get(SimpleSession, "dir", "")
		return session.Session.All(dir)->map((_, name) => {
			return fnamemodify(name, ':p:h:t')
		})
	})
	.Callback((attr) => {
		var dir = get(SimpleSession, "dir", "")
		session.Session.Load(dir, attr.args, attr.mods.silent)
	})

var group = "Sesssion"
var autocmds = []

if get(SimpleSession, 'saveOnVimLeave', false)
	autocmds->add({
			group: group,
			event: 'VimLeavePre',
			once: true,
			pattern: '*',
			cmd: 'silent SessionSave'
	})
endif

var bufEnter = get(SimpleSession, 'loadOnBufEnter', "")

if !empty(bufEnter)
	autocmds->add({
		grou: group,
		event: bufEnter,
		pattern: '*',
		once: true,
		cmd: 'silent SessionLoad',
	})
endif

autocmd_add(autocmds)
