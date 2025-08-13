vim9script

var grepprg = ["cgrep", "-r"]

export def AddTypeFilter(...types: list<string>)
	for type in types
		grepprg->add("--type-filter=" .. type)
	endfor
enddef

export def AddPruneDir(...dirs: list<string>)
	for dir in dirs
		grepprg->add("--prune-dir=" .. dir)
	endfor
enddef

export def AddKindFilter(...kinds: list<string>)
	for kind in kinds
		grepprg->add("--kind-filter=" .. kind)
	endfor
enddef

augroup cgrep
	au!
	au VimEnter * {
		grepprg->add("$*")
		&grepprg = grepprg->join(' ')
		&grepformat = "%-G,%f:%l:%c:%m"
	}
augroup END
