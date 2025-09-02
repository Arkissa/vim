vim9script

export def Cmd(...s: list<string>): string
	return s->join(' ')
enddef

export def Option(...s: list<string>): string
	return s->join(',')
enddef
