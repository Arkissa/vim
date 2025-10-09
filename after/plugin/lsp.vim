vim9script

import 'autocmd.vim'
import 'keymap.vim'
import autoload 'lsp/lsp.vim'
import autoload 'lsp/buffer.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = autocmd.Autocmd

const group = 'VIM9LSP'

# https://github.com/saccarosium/yegappan-lsp-settings/blob/ca7f3dd4f4390938d9ea18033b7a7729f3e5b162/plugin/lsp_settings.vim#L5
def LspHas(feature: string): bool
	return !buffer.CurbufGetServer(feature)->empty()
enddef

Autocmd.new('User')
	.Group(group)
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
