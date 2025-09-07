vim9script

if !exists("g:Linters")
	finish
endif

import autoload 'command.vim'

# type check
g:Linters->values()
	->map((_, d) => d.lint)
	->foreach((_, k: command.Execute) => {
	})

def Register()
	var conf = g:Linters[&filetype]
	if conf->has_key('onSaveCmd')
		autocmd_add([{
			group: group,
			event: 'BufWritePost',
			bufnr: bufnr(),
			replace: true,
			cmd: conf.onSaveCmd
		}])
	endif

	command.Command.new("Lint")
		.Bang()
		.Buffer()
		.Overlay()
		.NArgs(command.NArgs.Star)
		.Callback((attr) => {
			if attr.args =~ '^[a-zA-Z0-9]\+://'
				return
			endif

			conf.lint.Attr(attr).Run()
		})

	command.Command.new("LLint")
		.Bang()
		.Buffer()
		.Overlay()
		.NArgs(command.NArgs.Star)
		.Callback((attr) => {
			if attr.args =~ '^[a-zA-Z0-9]\+://'
				return
			endif

			conf.lint.Attr(attr, true).Run()
		})
enddef

var group = "Linter"

autocmd_add(g:Linters
	->keys()
	->map((_, t) => {
		return {
			group: group,
			event: 'FileType',
			pattern: t,
			replace: true,
			cmd: "Register()"}
	}))
