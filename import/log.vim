vim9script

enum Level
	Info('Question'),
	Warn('WarningMsg'),
	Error('Error')

	var Value: string
endenum

export def Info(msg: string)
	:redraw
	:echohl Question
	:echomsg $"Info: {msg}"
	:echohl None
enddef

export def Warn(msg: string)
	:redraw
	:echohl WarningMsg
	:echomsg $"Warn: {msg}"
	:echohl None
enddef

export def Error(msg: string)
	:redraw
	:echohl Error
	:echomsg $"Error: {msg}"
	:echohl None
enddef

def PopupNotification(msg: string, level: Level)
	popup_notification(msg, {
		col: &columns,
		pos: 'topright',
		time: 3000,
		close: 'click',
		highlight: level.Value
	})
enddef

export def PopInfo(msg: string)
	PopupNotification(msg, Level.Info)
enddef

export def PopWarn(msg: string)
	PopupNotification(msg, Level.Warn)
enddef

export def PopError(msg: string)
	PopupNotification(msg, Level.Error)
enddef
