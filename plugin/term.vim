vim9script

import '../autoload/term.vim'
import '../autoload/command.vim'

type Command = command.Command
type NArgs = command.NArgs

Command.new('Term')
	.NArgs(NArgs.Star)
	.Callback((attr) => {
		term.Manager.NewTerm(attr.args)
	})

Command.new('TermToggle')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		var pos = attr.mods.split
		if attr.mods.vertical
			pos = 'vertical ' .. pos
		elseif attr.mods.horizontal
			pos = 'horizontal ' .. pos
		endif

		term.Manager.ToggleWindow(pos)
	})

Command.new('TermToc')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		term.Manager.TermsToc()
	})

Command.new('TermNext')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		term.Manager.Slide(1)
	})

Command.new('TermPrev')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		term.Manager.Slide(-1)
	})

Command.new('TermKill')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		term.Manager.KillCurrentTerm()
	})

Command.new('TermKillAll')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		term.Manager.KillAllTerms()
	})
