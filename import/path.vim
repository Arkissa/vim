vim9script

export def OsStateDir(): string
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
