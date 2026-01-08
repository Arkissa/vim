vim9script


import 'vim.vim'
import 'command.vim'
import autoload './grepprg.vim'

class Cgrep extends grepprg.Grepprg
	var _args: list<string> = []

	def new(args: dict<any> = {})
		&grepprg = vim.Cmd(["cgrep", "-r", "$*"])
		&grepformat = vim.Option([
			'%-G',
			'%f:%l:%c:%m',
		])

		if args->has_key("types")
			extend(this._args, map(args.types, (_, type) => $"--type={type}"))
		endif

		if args->has_key("kinds")
			extend(this._args, map(args.kinds, (_, kind) => $"--kind={kind}"))
		endif

		if args->has_key("pruneDirs")
			extend(this._args, map(args.pruneDirs, (_, dir) => $"--prune-dir={dir}"))
		endif
	enddef

	def GetArgs(): list<string>
		return this._args
	enddef
endclass

export type Grep = Cgrep
