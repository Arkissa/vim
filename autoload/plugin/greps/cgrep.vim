vim9script

import autoload 'vim.vim'
import autoload 'command.vim'

class Cgrep extends command.ErrorFormat
	var _command = ["cgrep", "-r"]

	def new(args: dict<any> = {})
		if args->has_key("types")
			extend(this._command, map(args.types, (_, type) => $"-t {type}"))
		endif

		if args->has_key("kinds")
			extend(this._command, map(args.kinds, (_, kind) => $"-k {kind}"))
		endif

		if args->has_key("pruneDirs")
			extend(this._command, map(args.pruneDirs, (_, dir) => $"--prune-dir={dir}"))
		endif

		add(this._command, '$*')
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

export type Grep = Cgrep
