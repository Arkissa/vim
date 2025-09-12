vim9script

import '../autoload/term.vim'
import '../autoload/command.vim'
import '../autoload/keymap.vim'

type Command = command.Command
type NArgs = command.NArgs
type Bind = keymap.Bind
type Mods = keymap.Mods

Command.new('Term')
	.NArgs(NArgs.Star)
	.Count(20)
	.Callback((attr) => {
		var pos = attr.mods.split
		if attr.mods.vertical
			pos = 'vertical ' .. pos
		elseif attr.mods.horizontal
			pos = 'horizontal ' .. pos
		endif

		term.Manager.NewTerm(attr.args, pos, attr.count)
	})

Command.new('TermToggle')
	.NArgs(NArgs.Zero)
	.Count(20)
	.Callback((attr) => {
		var pos = attr.mods.split
		if attr.mods.vertical
			pos = 'vertical ' .. pos
		elseif attr.mods.horizontal
			pos = 'horizontal ' .. pos
		endif

		term.Manager.ToggleWindow('', pos, attr.count)
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

Bind.newMulti(Mods.n)
	.Silent()
	.Map('''<CR>', '<CMD>botright Term<CR>')
	.Map('<Leader>t', '<CMD>botright TermToggle<CR>')
	.Map('[t', '<CMD>TermPrev<CR>')
	.Map(']t', '<CMD>TermNext<CR>')
