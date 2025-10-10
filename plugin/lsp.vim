vim9script

import 'lsp.vim'
import 'log.vim'
import 'autocmd.vim'
import 'keymap.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

const group = 'VIM9LSP'

g:LspSetConfig('gopls', {
		filetype: ['go', 'gomod', 'gohtmltmpl', 'gotexttmpl'],
		path: 'gopls',
		workspaceConfig: {
			gopls: {
				gofumpt: true,
				staticcheck: true,
				completionBudget: '50ms',
			}
		}
})

Autocmd.new('User')
	.Group(group)
	.Pattern(['LspSetup'])
	.Callback(() => {
		g:LspOptionsSet(lsp.Option())
		g:LspAddServer(lsp.Config())
	})
