vim9script
packadd vim9-lsp

import autoload 'lsp/lsp.vim'
import autoload 'lsp/buffer.vim'
import autoload 'autocmd.vim'
import autoload 'keymap.vim'

type Autocmd = autocmd.Autocmd
type Bind = keymap.Bind
type Mods = keymap.Mods

# https://github.com/saccarosium/yegappan-lsp-settings/blob/ca7f3dd4f4390938d9ea18033b7a7729f3e5b162/plugin/lsp_settings.vim#L5
def LspHas(feature: string): bool
	return !buffer.CurbufGetServer(feature)->empty()
enddef

Autocmd.new('User')
	.Pattern(['LspAttached'])
	.Callback(() => {
		if LspHas('documentFormatting')
			:setlocal formatexpr=lsp.FormatExpr()
		endif

		:setlocal tagfunc=lsp.TagFunc

		Bind.new(Mods.i)
			.NoRemap()
			.Silent()
			.Buffer()
			.Map('<C-s>', '<CMD>LspShowSignature<CR>')

		Bind.new(Mods.n)
			.NoRemap()
			.Silent()
			.Buffer()
			.Map('<C-w>d', '<CMD>LspDiagCurrent<CR>')
			.Map(']e', '<CMD>LspDiagNextWrap<CR>')
			.Map('[e', '<CMD>LspDiagPrevWrap<CR>')
			.Map('<C-w>e', '<CMD>LspDiagShow<CR>')

			.When(funcref(LspHas, ['rename']))
			.Map('<Leader>r', '<CMD>LspRename<CR>')

			.When(funcref(LspHas, ['hover']))
			.Map('K', '<CMD>LspHover<CR>')

			.When(funcref(LspHas, ['implementation']))
			.Map('[D', '<CMD>LspPeekImpl<CR>')
			.Map(']D', '<CMD>LspGotoImpl<CR>')

			.When(funcref(LspHas, ['documentSymbol']))
			.Map('[I', '<CMD>LspDocumentSymbol<CR>')
			.Map(']I', '<CMD>LspOutline<CR>')

			.When(funcref(LspHas, ['definition']))
			.Map('gd', '<CMD>LspGotoDefinition<CR>')
			.Map('[d', '<CMD>LspPeekDefinition<CR>')

			.When(funcref(LspHas, ['typeDefinition']))
			.Map('gD', '<CMD>LspGotoTypeDef<CR>')
			.Map(']d', '<CMD>LspPeekTypeDef<CR>')

			.When(funcref(LspHas, ['codeAction']))
			.Map('<Leader>a', '<CMD>LspCodeAction<CR>')

			.Map('*', '<CMD>LspShowReferences<CR>')
	})

g:LspOptionsSet({
    autoComplete: false,
    autoHighlight: true,
    autoHighlightDiags: true,
    completionMatcher: 'fuzzy',
    completionMatcherValue: 1,
    diagSignErrorText: '✘',
    diagSignWarningText: '',
    diagSignHintText: '',
    diagSignInfoText: '',
    keepFocusInDiags: true,
    keepFocusInReferences: true,
    completionTextEdit: true,
	outlineOnWinSize: 100,
    popupBorder: true,
    popupBorderHighlight: 'Title',
    popupBorderHighlightPeek: 'Title',
    popupBorderSignatureHelp: true,
    popupHighlight: 'Normal',
    semanticHighlight: true,
    showDiagInBalloon: true,
    showDiagInPopup: true,
    showDiagWithSign: true,
    showInlayHints: true,
    showSignature: true,
    useQuickfixForLocations: true,
    usePopupInCodeAction: true,
    bufferCompletionTimeout: 100,
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
})

var lsp_servers = [
    {
		name: 'python',
		filetype: ['python'],
		path: 'basedpyright-langserver',
		args: ["--stdio"],
		workspaceConfig: {
			python: {
				autoSearchPaths: true,
				useLibraryCodeForTypes: true,
				analysis: {
					diagnosticMode: 'workspace',
					typeCheckingMode: 'recommended',
					inlayHints: {
						variableTypes: true,
						callArgumentNames: true,
						functionReturnTypes: true,
						genericTypes: true,
					}
				}
			}
		},
		syncInit: true,
    },
    {
		name: 'golang',
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
					'-tools/',
				],
				codelenses: {
					tests: true,
					tidy: true,
					upgrade_dependency: true,
					vendor: true,
				},
				usePlaceholders: true,
				gofumpt: true,
				analyses: {
					shadow: false,
					unusedparams: false,
					SA5008: false,
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
				symbolScope: 'workspace',
				semanticTokens: false,
			}
		}
	}
]

g:LspAddServer(lsp_servers->filter((_, server) => executable(server.path) == 1))
