vim9script

import autoload "buffer.vim"
import autoload "quickfix.vim"

def Buffers(bang: bool)
	var buffers = getbufinfo()
		->map((_, info) => buffer.Buffer.new(info.bufnr))
		->filter((_, b) => b.IsExists())
		->filter((_, b) => b.LineCount() != 0)

	if bang
		buffers = buffers->filter((_, b) => b.IsLoaded() && index(["netrw"], b.GetVar("&filetype")) == -1 )
	endif

	var qf = quickfix.Quickfix.new()
	qf.SetList(buffers->map((_, b) => b.QuickfixItem()), quickfix.Action.R)
	qf.Window()
enddef

:command -bang Buffers Buffers(empty(<q-bang>) ? true : false)
