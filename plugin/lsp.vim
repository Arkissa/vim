vim9script
packadd vim9-lsp

import autoload 'lsp/lsp.vim'
import autoload 'lsp/buffer.vim'
import 'autocmd.vim'
import 'keymap.vim'

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
			&l:formatexpr = 'lsp.FormatExpr()'
		endif

		&l:tagfunc = lsp.TagFunc

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
    autoComplete: true,
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
	ignoreMissingServer: false,
	outlineOnRight: true,
	outlineWinSize: 50,
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
	condensedCompletionMenu: true,
	filterCompletionDuplicates: true,
	useBufferCompletion: true,
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
