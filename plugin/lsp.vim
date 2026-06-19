vim9script

import 'vim.vim'
import 'thread.vim'
import 'autocmd.vim'

import autoload 'lsp.vim'

type Autocmd = autocmd.Autocmd

const group = "Lsp"

Autocmd.new('VimEnter')
	.Group(group)
	.Desc("load lsp")
	.Once()
	.Callback(() => {
		thread.Fork(() => {
			execute('packadd lsp')
		})
	})

Autocmd.new('User')
	.Group(group)
	.Pattern(['LspSetup'])
	.Callback(() => {
		g:LspAddServer(g:LspServer)
	})
	.Pattern(['LspDiagsUpdated'])
	.Callback(() => {
		lsp.DiagsUpdate()
	})
	.Pattern(['LspAttached'])
	.Callback(() => {
		lsp.Attached()
	})
