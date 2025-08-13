vim9script
packadd vim9-lsp

import autoload "lsp/lsp.vim"

autocmd User LspAttached {
    :setlocal tagfunc=lsp.TagFunc
    :setlocal formatexpr=lsp.FormatExpr()

    :nnoremap <silent> <buffer> K <CMD>LspHover<CR>
    :nnoremap <silent> <buffer> <Leader>r <CMD>LspRename<CR>
    :nnoremap <silent> <buffer> <Leader>a <CMD>LspCodeAction<CR>
    :xnoremap <silent> <buffer> <Leader>a <CMD>LspCodeAction<CR>
    :nnoremap <silent> <buffer> [d <CMD>LspPeekDefinition<CR>
    :nnoremap <silent> <buffer> ]d <CMD>LspPeekTypeDef<CR>
    :nnoremap <silent> <buffer> [D <CMD>LspPeekImpl<CR>
    :nnoremap <silent> <buffer> [I <CMD>LspDocumentSymbol<CR>
    :nnoremap <silent> <buffer> ]I <CMD>LspOutline<CR>
    :nnoremap <silent> <buffer> ]I <CMD>LspOutline<CR>
    :nnoremap <silent> <buffer> gd <CMD>LspGotoDefinition<CR>
    :nnoremap <silent> <buffer> gD <CMD>LspGotoTypeDef<CR>
    :nnoremap <silent> <buffer> * <CMD>LspPeekReferences<CR>
    :nnoremap <silent> <buffer> <C-w>d <CMD>LspDiagCurrent<CR>
    :nnoremap <silent> <buffer> ]e <CMD>LspDiagNextWrap<CR>
    :nnoremap <silent> <buffer> [e <CMD>LspDiagPrevWrap<CR>
    :nnoremap <silent> <buffer> <C-w>e <CMD>LspDiagShow<CR>
    :inoremap <silent> <buffer> <C-s> <CMD>LspShowSignature<CR>
}

g:LspOptionsSet({
    autoComplete: true,
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
    showSignature: false,
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
		args: ['serve'],
		syncInit: true,
		workspaceConfig: {
			go: {
				codelenses: {
					tests: true,
					tidy: true,
					upgrade_dependency: true,
					vendor: true,
				},
				usePlaceholders: true,
				gofumpt: true,
				analyss: {
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
				semanticTokens: true,
			}
		}
	}
]

g:LspAddServer(lsp_servers->filter((_, server) => executable(server.path) == 1))
