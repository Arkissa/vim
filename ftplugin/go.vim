vim9script

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_build_constraints = 1
g:go_highlight_generate_tags = 1

import 'vim.vim'
import 'log.vim'
import 'path.vim'
import 'keymap.vim'
import 'command.vim'
import 'autocmd.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type NArgs = command.NArgs
type Autocmd = autocmd.Autocmd
type Command = command.Command

&l:list = false
&l:formatprg = 'golangci-lint fmt --stdin'

const group = "Go"
:compiler go

def RealPath(pt: string): string
	if exists_compiled("+clipboard")
		var gopath = $"^{trim(system('go env GOPATH'))}/pkg/mod"
		if pt =~ gopath
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		var goroot = $"^{trim(system('go env GOROOT'))}"
		if pt =~ goroot
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		return fnamemodify(pt, ':.')
	else
		log.Error('clipboard feature not exists.')
		return ""
	endif
enddef

Autocmd.new('User')
	.Group(group)
	.Pattern(['LspAttached'])
	.Bufnr(bufnr())
	.Callback(() => {
		Bind.new(Mods.o)
			.NoRemap()
			.Buffer()
			.Callback('il', () => {
				if v:operator != 'y'
					return
				endif

				var p = $'{path.UnderPath(function(RealPath))}:{line('.')}'
				log.Info($'copy path to + registers: {p}')
				setreg('+', p)
			})
			.Callback('al', () => {
				if v:operator != 'y'
					return
				endif

				var p = $"{expand("%:p")}:{line('.')}"
				log.Info($'copy path to + registers: {p}')
				setreg('+', p)
			})
	})
	.Command('setlocal formatexpr=')

Command.new("Go")
	.Bang()
	.Overlay()
	.NArgs(NArgs.Star)
	.Buffer()
	.Command('Dispatch<bang> go <args>')
