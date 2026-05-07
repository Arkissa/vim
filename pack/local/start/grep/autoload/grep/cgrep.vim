vim9script

import 'vim.vim'
import autoload 'grep/grepprg.vim'

const prunes = ["proto", "3rd", "bin", "node_modules", "dist-newstyle", ".git", "target"]

export class Grep extends grepprg.Grepprg
	def Grepprg(): string
		return vim.Cmd(["cgrep", "-r", "$*"])
	enddef

	def GrepFormat(): string
		return vim.Option([
			'%-G',
			'%f:%l:%c:%m',
		])
	enddef

	def GetArgs(): list<string>
		return ['--kind=Language']->extend(prunes->mapnew((_, dir) => $"--prune-dir={dir}"))
	enddef
endclass
