vim9script

import "vim.vim"
import "command.vim"

class Grepprg extends command.ErrorFormat
	def Cmd(): string
		var args = []
		var ignores = split(&wildignore, ',')
		for ignore in ignores
			if ignore =~# '/'
				args->add($"--exclude-dir={ignore}")
			else
				args->add($"--exclude={ignore}")
			endif
		endfor

		return this.Expandcmd(substitute(&grepprg, '\$\*', $'{vim.Cmd(args)} $*', ''))
	enddef

	def Efm(): string
		return &grepformat
	enddef
endclass

export type Grep = Grepprg
