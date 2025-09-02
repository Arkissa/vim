vim9script

import "./log.vim"
import "./errorformat.vim" as efm

export def Run(bang: bool, args: string)
	var linter = get(b:, 'linter', "")
	if linter == ""
		log.Warn($"Warn: b:linter is empty")
		return
	endif

	efm.Command.new(linter, get(b:, 'linterformat', [])->join(','), bang).Run(args)
enddef
