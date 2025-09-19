vim9script

import '../autoload/vim.vim'
import '../autoload/path.vim'
import '../autoload/keymap.vim'
import '../autoload/command.vim'
import '../autoload/autocmd.vim' as au
import '../autoload/plugin/greps/cgrep.vim'

type Bind = keymap.Bind
type Mods = keymap.Mods
type Autocmd = au.Autocmd
type Command = command.Command
type NArgs = command.NArgs

:setlocal nolist
:setlocal nowrap
:setlocal formatprg=golangci-lint\ fmt\ --stdin

const group = "Go"

var autocmd = Autocmd.new('User')
	.Group(group)
	.Pattern(['LspAttached'])
	.Bufnr(bufnr())
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
		echoerr 'clipboard feature not exists.'
		return ""
	endif
enddef

autocmd.Callback(() => {
	Bind.new(Mods.n)
		.NoRemap()
		.Buffer()
		.ScriptCmd('yil', () => {
			setreg('+', $"{path.UnderPath(function(RealPath))}:{line('.')}")
		})
		.ScriptCmd('yal', () => {
			setreg('+', $"{expand("%:p")}:{line('.')}")
		})
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
	.Map('\g', '<CMD>vertical leftabove 100Term gemini<CR>')
