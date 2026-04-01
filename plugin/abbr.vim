vim9script

def ExpandCmd(lhs: string, rhs: string): string
	if !(getcmdtype() ==# ':' && getcmdline() ==# lhs)
		return lhs
	endif

	return rhs
enddef

def CmdAlias(lhs: string, ...rhs: list<string>)
	execute($"cnoreabbrev <expr> {lhs} ExpandCmd('{lhs}', '{rhs->join(' ')}')")
enddef

CmdAlias('grep', 'Grep')
CmdAlias('make', 'Make')
CmdAlias('git', 'Git')
