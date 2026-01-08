vim9script

import 'vim.vim'
import autoload './grepprg.vim'

class GnuGrep extends grepprg.Grepprg
	var _args: list<string> = []

	def new(args: dict<any> = {})
		&grepprg = vim.Cmd(["grep", "-r", '-n', "$*"])
		&grepformat = vim.Option([
			'%-G',
			'%f:%l:%m',
		])

		extend(this._args, map(get(args, 'exclude', []), (_, file) => $"--exclude={file}"))
		extend(this._args, map(get(args, 'exclude_dir', []), (_, dir) => $"--exclude-dir={dir}"))
	enddef

	def GetArgs(): list<string>
		return this._args
	enddef
endclass

export type Grep = GnuGrep
