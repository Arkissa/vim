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
				directoryFilters: [
					'-**/node_modules',
					'-3rd/',
					'-**/bin',
					'-**/logs',
					'-app/deploy',
					'-proto/',
					'-docs/',
					# '-tools/',
					'-common/redisx/',
				],
				workspaceFiles: [
					'app/**',
				],
				completionBudget: '50ms',
				codelenses: {
					tests: true,
					tidy: true,
					upgrade_dependency: true,
					vendor: true,
				},
				usePlaceholders: true,
				gofumpt: true,
				analyses: {
					shadow: false, unusedparams: false, SA5008: false,
					QF1002: false, QF1003: false, any: false, SA4: false,
					ST1020: false, ST1003: false, ST1001: false,
					ST1021: false, ST1022: false,
					ST1000: false, S1033: false, S1028: false, # temporary
				},
				staticcheck: true,
				hints: {
					assignVariableTypes: true,
					compositeLiteralFields: true,
					constantValues: true,
					rangeVariableTypes: true,
					parameterNames: true,
					functionTypeParameters: true
				},
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
