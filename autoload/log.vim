vim9script

export def Info(msg: string)
	:echohl Question
	:echomsg $"Info: {msg}"
	:echohl None
enddef

export def Warn(msg: string)
	:echohl WarningMsg
	:echomsg $"Warn: {msg}"
	:echohl None
enddef

export def Error(msg: string)
	:echohl WarningMsg
	:echomsg $"Error: {msg}"
	:echohl None
enddef
