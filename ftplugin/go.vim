vim9script

import autoload 'vim.vim'
import autoload 'greps/cgrep.vim'
import autoload 'command.vim'

:setlocal nolist
:setlocal nowrap

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1

g:Grep = cgrep.Cgrep.new({
	types: ["Go"],
	pruneDirs: ["proto"],
	kind: ["Language"]
})

command.Command.new("Go")
	.Bang()
	.Overlay()
	.NArgs(command.NArgs.Star)
	.Command('Dispatch<bang> go <args>')

if exists("+clipboard")
	import autoload 'path.vim'
	def RealPath(pt: string): string
		var gopath = $"^{trim(system('go env GOPATH'))}/pkg/mod"
		if pt =~ gopath
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		var goroot = $"^{trim(system('go env GOPATH'))}/pkg/mod"
		if pt =~ goroot
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		return pt
	enddef

	autocmd User LspAttached {
		:nnoremap yil <ScriptCmd>setreg('+', $"{path.UnderPath(function(RealPath))}:{line('.')}")<CR>
		:nnoremap yal <ScriptCmd>setreg('+', $"{expand("%:p")}:{line('.')}")<CR>
	}
endif
