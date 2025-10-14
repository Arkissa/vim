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
			.Map('<C-s>', Bind.Cmd('LspShowSignature'))

		Bind.new(Mods.n)
			.NoRemap()
			.Silent()
			.Buffer()
			.Map('<C-w>d', Bind.Cmd('LspDiagCurrent'))
			.Map(']e', Bind.Cmd('LspDiagNextWrap'))
			.Map('[e', Bind.Cmd('LspDiagPrevWrap'))
			.Map('<C-w>e', Bind.Cmd('LspDiagShow'))

			.When(funcref(LspHas, ['rename']))
			.Map('<Leader>r', Bind.Cmd('LspRename'))

			.When(funcref(LspHas, ['hover']))
			.Map('K', Bind.Cmd('LspHover'))

			.When(funcref(LspHas, ['implementation']))
			.Map('[D', Bind.Cmd('LspPeekImpl'))
			.Map(']D', Bind.Cmd('LspGotoImpl'))

			.When(funcref(LspHas, ['documentSymbol']))
			.Map('[I', Bind.Cmd('LspDocumentSymbol'))
			.Map(']I', Bind.Cmd('LspOutline'))

			.When(funcref(LspHas, ['definition']))
			.Map('gd', Bind.Cmd('LspGotoDefinition'))
			.Map('[d', Bind.Cmd('LspPeekDefinition'))

			.When(funcref(LspHas, ['typeDefinition']))
			.Map('gD', Bind.Cmd('LspGotoTypeDef'))
			.Map(']d', Bind.Cmd('LspPeekTypeDef'))

			.When(funcref(LspHas, ['codeAction']))
			.Map('<Leader>a', Bind.Cmd('LspCodeAction'))

			.Map('*', Bind.Cmd('LspShowReferences'))
	})
