vim9script

import 'buffer.vim'
import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

const group = "HaskellPreview"

export class Preview
	static var _b: buffer.Buffer

	static def _Init()
		if _b != null_object
			return
		endif

		_b = buffer.Buffer.new(group)
		_b.SetVar('&buftype', 'nofile')
		_b.SetVar('&bufhidden', 'hide')
		_b.SetVar('&swapfile', false)
		_b.SetVar('&buflisted', false)
		_b.Load()

		Autocmd.new('BufHidden')
			.Group(group)
			.Bufnr(_b.bufnr)
			.Replace()
			.Callback(_b.Clear)
	enddef

	static def Show(lines: list<string>)
		_Init()

		if !_b->empty()
			_b.Clear()
		endif

		defer _b.SetVar('&modified', false)

		_b.SetLines(lines, 1)

		if !_b.InWindow()
			execute($'pbuffer {_b.bufnr}', 'silent!')
		endif

		execute('wincmd P')
		execute($'resize {min([_b.LineCount(), &previewheight])}')
		execute('wincmd p')
	enddef
endclass

export class Popup
endclass
