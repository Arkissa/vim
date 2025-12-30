vim9script

import 'lsp.vim'
import 'vim.vim'
import 'keymap.vim'
import 'autocmd.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

const group = 'VIM9LSP'

var defaultLspConfig = [
	{
		name: 'gopls',
		filetype: ['go', 'gomod', 'gohtmltmpl', 'gotexttmpl'],
		path: 'gopls',
		workspaceConfig: {
			gopls: {
				directoryFilters: [],
				workspaceFiles: [],
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
					ST1000: false, S1033: false, S1028: false,
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
	},
	{
		name: 'jdtls',
		filetype: 'java',
		path: 'jdtls',
		workspaceConfig: {
			java: {
				errors: {
					incompleteClasspath: {
						severity: "warning"
					}
				},
				configuration: {
					updateBuildConfiguration: "interactive",
					maven: {
						userSettings: null
					}
				},
				foldingRange: {
					enable: true
				},
				import: {
					gradle: {
						enabled: true
					},
					maven: {
						enabled: true
					},
					exclusions: [
						"**/node_modules/**",
						"**/.metadata/**",
						"**/archetype-resources/**",
						"**/META-INF/maven/**",
						"/**/test/**"
					]
				},
				referencesCodeLens: {
					enabled: false
				},
				signatureHelp: {
					enabled: false
				},
				implementationCodeLens: "all",
				format: {
					enabled: true
				},
				saveActions: {
					organizeImports: true
				},
				contentProvider: {
					preferred: null
				},
				autobuild: {
					enabled: false
				},
				completion: {
					favoriteStaticMembers: [
						"org.junit.Assert.*",
						"org.junit.Assume.*",
						"org.junit.jupiter.api.Assertions.*",
						"org.junit.jupiter.api.Assumptions.*",
						"org.junit.jupiter.api.DynamicContainer.*",
						"org.junit.jupiter.api.DynamicTest.*"
					],
					importOrder: [
						"java",
						"javax",
						"com",
						"org"
					]
				}
			}
		},
	},
]

g:LspConf = extend(get(g:, 'LspConf', []), defaultLspConfig)

const option = {
	autoComplete: false,
	omniComplete: true,
    autoHighlight: true,
    autoHighlightDiags: true,
    completionMatcher: 'fuzzy',
	completionTextEdit: true,
    diagSignErrorText: '✘',
    diagSignWarningText: '',
    diagSignHintText: '',
    diagSignInfoText: '',
	snippetSupport: true,
    keepFocusInDiags: true,
    keepFocusInReferences: true,
	ignoreMissingServer: true,
	outlineOnRight: true,
	outlineWinSize: 50,
    popupBorder: true,
	popupBorderCompletion: true,
	definitionFallback: true,
	hoverFallback: true,
    popupBorderHighlight: 'Title',
    popupBorderHighlightPeek: 'Title',
    popupBorderSignatureHelp: true,
    popupHighlight: 'Normal',
    semanticHighlight: false,
    showDiagInBalloon: true,
    showDiagInPopup: true,
    showDiagWithSign: true,
    showInlayHints: true,
    showSignature: true,
	condensedCompletionMenu: true,
	filterCompletionDuplicates: true,
    useQuickfixForLocations: true,
    usePopupInCodeAction: true,
    customCompletionKinds: true,
    completionKinds: {
		Text: '󰦨',
		Method: '',
		Function: '󰡱',
		Constructor: '',
		Field: '',
		Variable: '',
		Class: '',
		Interface: '',
		Module: '',
		Property: '',
		Unit: '󰊱',
		Value: '',
		Enum: '',
		Keyword: '',
		Snippet: '',
		Color: '',
		File: '',
		Reference: '',
		Folder: '󰣞',
		EnumMember: '',
		Constant: '',
		Struct: '',
		Event: '',
		Operator: '',
		TypeParameter: '',
		Buffer: ''
    },
}

Autocmd.new('User')
	.Group(group)
	.Pattern(['LspSetup'])
	.Callback(() => {
		g:LspOptionsSet(option)
		g:LspAddServer(g:LspConf)
	})
