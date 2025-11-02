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
	.Bang()
	.Complete(command.Complete.ShellCmd)
	.Callback((attr) => {
		var pos = attr.mods.split
		if attr.mods.vertical
			pos = 'vertical ' .. pos
		elseif attr.mods.horizontal
			pos = 'horizontal ' .. pos
		endif

		terminal.Manager.NewTerminal(attr.bang, attr.args, pos, attr.count)
	})

Command.new('TermToggle')
	.NArgs(NArgs.Zero)
	.Count()
	.Bang()
	.Callback((attr) => {
		var pos = attr.mods.split
		if attr.mods.vertical
			pos = 'vertical ' .. pos
		elseif attr.mods.horizontal
			pos = 'horizontal ' .. pos
		endif

		terminal.Manager.ToggleWindow(attr.bang, '', pos, attr.count)
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
	.Map('\t', Bind.Cmd('botright 10Term'))
	.Map('<Leader>tt', Bind.Cmd('TermToggle!'))
	.Map('<Leader>tk', Bind.Cmd('TermKill'))
	.Map('<Leader>ta', Bind.Cmd('TermKillAll'))
	.Map('[t', Bind.Cmd('TermPrev'))
	.Map(']t', Bind.Cmd('TermNext'))

Bind.new(Mods.t)
	.Silent()
	.Map('<C-\>[', Bind.Cmd('TermPrev'))
	.Map('<C-\>]', Bind.Cmd('TermNext'))
	.Map('<C-\>k', Bind.Cmd('TermKill'))
	.Map('<C-\>a', Bind.Cmd('TermKillAll'))
