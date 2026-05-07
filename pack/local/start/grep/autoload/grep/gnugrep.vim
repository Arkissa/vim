vim9script

import 'vim.vim'
import autoload 'grep/grepprg.vim'

export class Grep extends grepprg.Grepprg
	def Grepprg(): string
		return vim.Cmd(["grep", "-r", '-n', "$*"])
	enddef

	def GrepFormat(): string
		return vim.Option([
			'%-G',
			'%f:%l:%m',
		])
	enddef

	def GetArgs(): list<string>
		return ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git"]->map((_, dir) => $"--exclude-dir={dir}")
	enddef
endclass
