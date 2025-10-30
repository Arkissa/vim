vim9script

import 'window.vim'
import 'buffer.vim'
import 'keymap.vim'
import 'autocmd.vim'
import 'command.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Window = window.Window
type Buffer = buffer.Buffer
type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = 'DiffOrig'

def DiffOrig()
	var current = Buffer.newCurrent()
	if !current.Readable() || current.GetVar('&buftype') != ""
		return
	endif

	var ft = current.GetVar('&filetype')
	if index(['xxd', 'gitcommit', 'gitrebase', 'netrw', '', 'help', 'tutor'], ft) != -1
		return
	endif

	if ft =~ '^.\{-\}://'
		return
	endif

	execute('diffthis')
	var currentWin = Window.newCurrent()
	var win = Window.new("vertical botright")
	win.Open()

	Autocmd.new('BufWriteCmd')
		.Group(group)
		.Once()
		.Replace()
		.Bufnr(current.bufnr)
		.Callback(() => {
			current.WriteFile()
			execute('edit')
			execute('write!')
		})

	Autocmd.new('WinClosed')
		.Group(group)
		.Once()
		.Pattern([win.winnr->string()])
		.Callback(() => {
			currentWin.Execute('diffoff')
		})

	win.ExecuteCallback(() => {
		execute($'read {current.name}')

		var buf = Buffer.newCurrent()
		buf.DeleteLine(1)
		buf.SetVar('&filetype', ft)
		buf.SetVar('&filetype', ft)
		buf.SetVar('&buftype', 'nofile')
		buf.SetVar('&bufhidden', 'wipe')
		buf.SetVar('&swapfile', false)
		buf.SetVar('&buflisted', false)

		execute('diffthis')
	})
enddef

Command.new('DiffOrig').Callback(DiffOrig)

Bind.new(Mods.n)
	.Silent()
	.Map('<M-d>', Bind.Cmd('DiffOrig'))
