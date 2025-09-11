vim9script

export def Info(msg: string) # {{{1
	:echohl Question
	:echomsg $"Info: {msg}"
	:echohl None
enddef

export def Warn(msg: string) # {{{1
	:echohl WarningMsg
	:echomsg $"Warn: {msg}"
	:echohl None
enddef

export def Error(msg: string) # {{{1
	:echohl WarningMsg
	:echomsg $"Error: {msg}"
	:echohl None
enddef
