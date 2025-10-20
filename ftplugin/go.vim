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
&l:wrap = false
&l:formatprg = 'golangci-lint fmt --stdin'

const group = "Go"
:compiler go

def RealPath(pt: string): string
	if exists_compiled("+clipboard")
		var gopath = $"^{trim(system('go env GOPATH'))}/pkg/mod"
		echom gopath
		if pt =~ gopath
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		var goroot = $"^{trim(system('go env GOROOT'))}"
		if pt =~ goroot
			return trim(substitute(pt, gopath, '', ''), '/')
		endif

		return fnamemodify(pt, ':.')
	else
		echoerr 'clipboard feature not exists.'
		return ""
	endif
enddef

Autocmd.new('User')
	.Group(group)
	.Pattern(['LspAttached'])
	.Bufnr(bufnr())
	.Callback(() => {
		Bind.new(Mods.n)
			.NoRemap()
			.Buffer()
			.Callback('yil', () => {
				setreg('+', $"{path.UnderPath(function(RealPath))}:{line('.')}")
			})
			.Callback('yal', () => {
				setreg('+', $"{expand("%:p")}:{line('.')}")
			})
	})
	.When(() => executable('golangci-lint') == 1)
	.Command('setlocal formatexpr=')
	.When(() => executable('golangci-lint') != 1)
	.Callback(() => {
		Autocmd.new('BufWritePre')
			.Group(group)
			.Bufnr(bufnr())
			.Pattern(['*.go'])
			.Command('LspFormat')
	})

Command.new("Go")
	.Bang()
	.Overlay()
	.NArgs(NArgs.Star)
	.Buffer()
	.Command('Dispatch<bang> go <args>')

Bind.new(Mods.n)
	.Silent()
	.Buffer()
	.Map('\g', Bind.Cmd('vertical leftabove 100Term gemini'))
