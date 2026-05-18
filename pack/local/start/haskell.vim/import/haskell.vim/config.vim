vim9script

export def GetVar(name: string): any
	return get(b:, name, get(g:, name, null))
enddef
