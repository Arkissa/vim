vim9script

import autoload 'lsp/buffer.vim'

export def OsStateDir(): string # {{{1
    var stateDir = has('win32') || has('win64')
	? $LOCALAPPDATA .. '/vim'
	: ($XDG_STATE_HOME !=# ''
	    ? $XDG_STATE_HOME .. '/vim'
	    : expand('~/.local/state/vim'))

    if !isdirectory(stateDir)
		mkdir(stateDir, 'p')
    endif

    return stateDir
enddef

export def UnderPath(RealPath: func(string): string): string # {{{1
	var server = buffer.CurbufGetServer()
	if server == null_dict
		return ""
	endif

	var file = expand('%:p')
	var workspace = server.workspaceFolders
		->map((_, folder) => "^" .. folder)
		->filter((_, folder) => file =~# folder)

	if !workspace->empty()
		return trim(substitute(file, workspace[0], '', ''), '/')
	endif

	return RealPath(file)
enddef
