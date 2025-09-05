vim9script

if !exists("g:Linters")
	finish
endif

import autoload 'command.vim'

# type check
g:Linters->values()->foreach((_, k: command.Execute) => {
})

def Register()
	var linter = g:Linters[&filetype]
	command.Command.new("Lint")
		.Bang()
		.Buffer()
		.Overlay()
		.NArgs(command.NArgs.Star)
		.Callback((attr) => {
			linter.Attr(attr).Run()
		})
enddef

var group = "Linter"
for t in g:Linters->keys()
	autocmd_add([{
		group: group,
		event: 'FileType',
		pattern: t,
		cmd: "Register()"
	}])
endfor
