vim9script

import autoload 'buffer.vim'
import autoload 'quickfix.vim'
import autoload 'command.vim'

command.Command.new("Buffers")
	.Bang()
	.Callback((attr) => {
		var buffers = getbufinfo()
			->map((_, info) => buffer.Buffer.newByBufnr(info.bufnr))
			->filter((_, b) => b.LineCount() != 0)

		if !attr.bang
			buffers = buffers->filter((_, b) => b.Listed())
		endif

		var qf = quickfix.Quickfix.newCurrent()

		var items = buffers->map((_, b) => quickfix.QuickfixItem.newByBuffer(b))
		qf.SetList(items, quickfix.Action.R)
		qf.Window()
	})
