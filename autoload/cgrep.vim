vim9script

var grepprg = ["cgrep", "-r"]

export def Config(conf: dict<any>)
	if conf->has_key("types")
		grepprg->extend(map(conf.types, (_, type) => $"--type-filter={type}"))
	endif

	if conf->has_key("dirs")
		grepprg->extend(map(conf.dirs, (_, dir) => $"--prune-dir={dir}"))
	endif

	if conf->has_key("kinds")
		grepprg->extend(map(conf.kinds, (_, kind) => $"--kind-filter={kind}"))
	endif
enddef

# augroup cgrep
# 	au!
# 	au VimEnter * {
# 		grepprg->add("$*")
# 		&grepprg = grepprg->join(' ')
# 		&grepformat = "%-G,%f:%l:%c:%m"
# 	}
# augroup END
