vim9script

import autoload "lsp/lsp.vim"

var lspOpts = {
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
}

autocmd User LspSetup g:LspOptionsSet(lspOpts)
autocmd User LspAttached {
    :setlocal tagfunc=lsp.TagFunc
    :setlocal formatexpr=lsp.FormatExpr

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
    :nnoremap <silent> <buffer> * <CMD>LspShowReferences<CR>
    :nnoremap <silent> <buffer> <C-w>d <CMD>LspDiagCurrent<CR>
    :nnoremap <silent> <buffer> [e <CMD>LspDiagNextWrap<CR>
    :nnoremap <silent> <buffer> ]e <CMD>LspDiagPrevWrap<CR>
    :nnoremap <silent> <buffer> <C-w>e <CMD>LspDiagShow<CR>
    :nnoremap <silent> <buffer> LspCodeAction
}
