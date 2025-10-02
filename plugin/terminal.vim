vim9script

import 'command.vim'
import 'keymap.vim'
import '../autoload/terminal.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type NArgs = command.NArgs
type Command = command.Command

Command.new('Term')
	.NArgs(NArgs.Star)
	.Count()
	.Complete(command.Complete.ShellCmd)
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
	.Count()
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
		terminal.Manager.SlideRight()
	})

Command.new('TermPrev')
	.NArgs(NArgs.Zero)
	.Callback((attr) => {
		terminal.Manager.SlideLeft()
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
	.Map('\t', '<CMD>botright 10Term<CR>')
	.Map('<Leader>tt', '<CMD>botright 10TermToggle<CR>')
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
