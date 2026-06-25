vim9script

g:go_highlight_types = 1
g:go_highlight_fields = 1
g:go_highlight_functions = 1
g:go_highlight_function_calls = 1
g:go_highlight_operators = 1
g:go_highlight_extra_types = 1
g:go_highlight_generate_tags = 1
g:go_highlight_build_constraints = 1
g:go_fold_enable = ['block', 'import', 'varconst', 'package_comment']
g:go_highlight_array_whitespace_error = 1
g:go_highlight_chan_whitespace_error = 1
g:go_highlight_space_tab_error = 1
g:go_highlight_trailing_whitespace_error = 1
g:go_highlight_format_strings = 1

import 'vim.vim'
import 'log.vim'
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

				var projectDir = fnamemodify(vim.FindMarks(getcwd(), ["go.work", "go.mod", ".git"]), ':p:h')
				var p = $'{substitute(expand('%:p'), $'{projectDir}/', '', '')}:{line('.')}'
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
	.Command('terminal go <args>')
