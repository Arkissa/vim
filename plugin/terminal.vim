vim9script

import '../autoload/command.vim'
import '../autoload/keymap.vim'
import '../autoload/plugin/terminal.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type NArgs = command.NArgs
type Command = command.Command

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

		terminal.Manager.NewTerminal(attr.args, pos, attr.count)
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

		terminal.Manager.ToggleWindow('', pos, attr.count)
	})

Command.new('TermNext')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		terminal.Manager.Slide(1)
	})

Command.new('TermPrev')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		terminal.Manager.Slide(-1)
	})

Command.new('TermKill')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		terminal.Manager.KillCurrentTerminal()
	})

Command.new('TermKillAll')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		terminal.Manager.KillAllTerminals()
	})

Bind.new(Mods.n)
	.Silent()
	.Map('\t', '<CMD>botright Term<CR>')
	.Map('<Leader>tt', '<CMD>botright TermToggle<CR>')
	.Map('<Leader>tk', '<CMD>TermKill<CR>')
	.Map('<Leader>ta', '<CMD>TermKillAll<CR>')
	.Map('[t', '<CMD>TermPrev<CR>')
	.Map(']t', '<CMD>TermNext<CR>')

Bind.new(Mods.t)
	.Silent()
	.Map('<C-\>[', '<CMD>TermPrev<CR>')
	.Map('<C-\>]', '<CMD>TermNext<CR>')
	.Map('<C-\>k', '<CMD>TermKill<CR>')
	.Map('<C-\>a', '<CMD>TermKillAll<CR>')
