vim9script

import autoload 'job.vim' as jb
import autoload 'buffer.vim'

export class Delve extends jb.Prompt # {{{1
	def new() # {{{2
		this._promptBufferName = 'dlv'
		this._cmd = $'dlv exec ./demo'
	enddef # }}}

	def Callback(pt: buffer.Prompt, chan: channel, msg: string) # {{{2
		if msg =~# $'^{this.Prompt()}'
			return
		endif

		pt.AppendLine(msg)
	enddef # }}}

	def ExitCb(pt: buffer.Prompt, job: job, code: number) # {{{2
	enddef # }}}

	def Prompt(): string # {{{2
		return '(dlv) '
	enddef # }}}
endclass # }}}
