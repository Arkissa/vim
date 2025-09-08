vim9script
packadd vim9-lsp

import autoload 'lsp/lsp.vim'
import autoload 'lsp/buffer.vim'

# https://github.com/saccarosium/yegappan-lsp-settings/blob/ca7f3dd4f4390938d9ea18033b7a7729f3e5b162/plugin/lsp_settings.vim#L5
def LspHas(feature: string): bool
	return !buffer.CurbufGetServer(feature)->empty()
enddef

autocmd User LspAttached {
	if LspHas('documentFormatting')
		:setlocal formatexpr=lsp.FormatExpr()
	endif

	if LspHas('hover')
		:nnoremap <silent> <buffer> K <CMD>LspHover<CR>
	endif

	if LspHas('rename')
		:nnoremap <silent> <buffer> <Leader>r <CMD>LspRename<CR>
	endif

	if LspHas('implementation')
		:nnoremap <silent> <buffer> [D <CMD>LspPeekImpl<CR>
	endif

	if LspHas('documentSymbol')
		:nnoremap <silent> <buffer> [I <CMD>LspDocumentSymbol<CR>
		:nnoremap <silent> <buffer> ]I <CMD>LspOutline<CR>
	endif

	if LspHas('definition')
		:setlocal tagfunc=lsp.TagFunc
		:nnoremap <silent> <buffer> gd <CMD>LspGotoDefinition<CR>
		:nnoremap <silent> <buffer> [d <CMD>LspPeekDefinition<CR>
	endif

	if LspHas('typeDefinition')
		:nnoremap <silent> <buffer> gD <CMD>LspGotoTypeDef<CR>
		:nnoremap <silent> <buffer> ]d <CMD>LspPeekTypeDef<CR>
	endif

	if LspHas('codeAction')
		:nnoremap <silent> <buffer> <Leader>a <CMD>LspCodeAction<CR>
	endif

	if LspHas('references')
		:nnoremap <silent> <buffer> * <CMD>LspShowReferences<CR>
	endif

    :nnoremap <silent> <buffer> <C-w>d <CMD>LspDiagCurrent<CR>
    :nnoremap <silent> <buffer> ]e <CMD>LspDiagNextWrap<CR>
    :nnoremap <silent> <buffer> [e <CMD>LspDiagPrevWrap<CR>
    :nnoremap <silent> <buffer> <C-w>e <CMD>LspDiagShow<CR>
    :inoremap <silent> <buffer> <C-s> <CMD>LspShowSignature<CR>
}

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
				semanticTokens: false,
			}
		}
	}
]

g:LspAddServer(lsp_servers->filter((_, server) => executable(server.path) == 1))
