vim9script

import '../command.vim'
import '../vim.vim'

var defaultArgs: list<string>

export class Cgrep extends command.ErrorFormat
	var _command = ["cgrep", "-r"]

	def new(args: dict<any> = {})
		extend(this._command, defaultArgs)

		if args->has_key("types")
			extend(this._command, map(args.types, (_, type) => $"-t {type}"))
		endif

		if args->has_key("kinds")
			extend(this._command, map(args.kinds, (_, kind) => $"-k {kind}"))
		endif

		if args->has_key("pruneDirs")
			extend(this._command, map(args.pruneDirs, (_, dir) => $"--prune-dir={dir}"))
		endif
	enddef

	def Cmd(): string
		return join(this._command, ' ')
	enddef

	def Efm(): string
		return vim.Option([
			'%-G',
			'%f:%l:%c:%m',
		])
	enddef
endclass

export def SetDefault(args: dict<any>)
	if args->has_key("types")
		defaultArgs->extend(map(args.types, (_, type) => $"-t {type}"))
	endif

	if args->has_key("types")
		defaultArgs->extend(map(args.types, (_, type) => $"-t {type}"))
	endif

	if args->has_key("kinds")
		defaultArgs->extend(map(args.kinds, (_, kind) => $"-k {kind}"))
	endif

	if args->has_key("pruneDirs")
		defaultArgs->extend(map(args.pruneDirs, (_, dir) => $"--prune-dir={dir}"))
	endif
enddef
