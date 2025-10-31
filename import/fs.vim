vim9script

const iswin = has('win')
const osSep = iswin ? '\' : '/'

def Dirname(fname: string): string
	if fname == null_string
		return fname
	endif

	var file = fname
	if iswin
		file = file->substitute(osSep, '/', 'g')
		if file =~ '^\w:/\?$'
			return file
		endif
	endif

	if file !~# '/'
		return '.'
	endif

	if file == '/' || file =~ '^/[^/]\+$'
		return '/'
	endif

	final dir = trim(file->matchstr('\v^(/?.+)/'), '/', 2)
	if iswin && dir =~ '^\w:$'
		return dir .. '/'
	endif

	return dir ?? '/'
enddef
