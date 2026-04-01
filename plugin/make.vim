vim9script

import 'vim.vim'
import 'keymap.vim'
import 'command.vim'
import 'autocmd.vim'
import 'log.vim'

import autoload 'make.vim'

type Make = make.Make
type Bind = keymap.Bind
type Mods = keymap.Mods
type NArgs = command.NArgs
type Complete = command.Complete
type Command = command.Command
type Autocmd = autocmd.Autocmd

Autocmd.new('QuickFixCmdPost')
	.Group('Make')
	.Pattern(['Make'])
	.Callback((attr) => {
		var qf = attr.data
		if !qf.IsEmpty()
			qf.Open()
		endif
	})

# TODO: Add command history for make.Make and support output terminal or
# quickfix, and entry '\<CR>' goto file by file[:line[:col]] of formats text in
# terminal output.

Command.new('Make')
	.NArgs(NArgs.Star)
	.Callback((attr) => {
		Make.new().Attr(attr).Run()
	})

def GetPIDMaxNumber(ms: list<dict<any>>): number
	return max(ms->mapnew((_, m) => string(m.process))->mapnew((_, ps) => len(ps)))
enddef

def ShowMakes()
	var infos = Make.GetHistory()->mapnew((_, info) => info.Info())
	var n = GetPIDMaxNumber(infos)
	var format = $"%s%-{n}s %s"

	echohl Title
	echo printf(format, "  ", "pid", "command")
	echohl None
	echo "\r"

	if infos->len() == 0
		return
	endif

	for info in infos[ : -2]
		echo printf(format, "  ", info.process, info.cmd->join(' '))
	endfor

	var lastInfo = infos[-1]
	echo printf(format, "> ", lastInfo.process, lastInfo.cmd->join(' '))
enddef

Command.new('AbortMake')
	.NArgs(NArgs.Star)
	.Complete(Complete.CustomList, (_, _, _): list<string> => {
		return Make.GetHistory()->mapnew((_, m) => m.Info().process->string())
	})
	.Callback((attr) => {
		var makes = Make.GetHistory()
		if makes->len() == 1
			makes[0].Stop()
			return
		endif

		if attr.args == ""
			ShowMakes()
			return
		endif

		makes->filter((_, m) => vim.Contains(attr.fargs, m.Info().process->string()))
			->foreach((_, m) => m.Stop())
	})
