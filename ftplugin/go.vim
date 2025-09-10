vim9script

import autoload 'vim.vim'
import autoload 'greps/cgrep.vim'
import autoload 'command.vim'
import autoload 'autocmd.vim'

type Autocmd = autocmd.Autocmd
type Command = command.Command
type NArgs = command.NArgs

const group = "Go"

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

Command.new("Go")
	.Bang()
	.Overlay()
	.NArgs(NArgs.Star)
	.Command('Dispatch<bang> go <args>')

var au = Autocmd.new('User')
	.Group(group)
	.Pattern(['LspAttached'])
	.Bufnr(bufnr())
	.Callback(() => {
		Autocmd.new('BufWritePre')
			.Group(group)
			.Bufnr(bufnr())
			.Pattern(['*.go'])
			.Command('LspFormat')
	})

if exists("+clipboard")
	import autoload 'path.vim'
	import autoload 'keymap.vim'

	type Bind = keymap.Bind
	type Mods = keymap.Mods

	def RealPath(pt: string): string
		var gopath = $"^{trim(system('go env GOPATH'))}/pkg/mod"
		if pt =~ gopath
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		var goroot = $"^{trim(system('go env GOROOT'))}"
		if pt =~ goroot
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		return fnamemodify(pt, ':.')
	enddef

	au.Callback(() => {
		Bind.new(Mods.n)
			.NoRemap()
			.ScriptCmd('yil', () => {
				setreg('+', $"{path.UnderPath(function(RealPath))}:{line('.')}")
			})
			.ScriptCmd('yal', () => {
				setreg('+', $"{expand("%:p")}:{line('.')}")
			})
	})
endif
