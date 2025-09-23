vim9script

if !exists("g:LinterConfig")
	finish
endif

import '../autoload/command.vim'
import '../autoload/autocmd.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = "Linter"

const fts = g:LinterConfig->keys()

for [ft, conf] in g:LinterConfig->items()
	import autoload $'{conf.name}.vim'

	var expr = $'{fnamemodify(conf.name, ':t:r')}.Lint.new()'
	var Register = () => {
		if conf->has_key('onSaveCmd')
			Autocmd.new('BufWritePost')
				.Group(group)
				.Bufnr(bufnr())
				.Replace()
				.Command(conf.onSaveCmd)
		endif

		var lint: command.Execute = eval(expr)

		Command.new("Lint")
			.Bar()
			.Bang()
			.Buffer()
			.Overlay()
			.NArgs(command.NArgs.Star)
			.Callback((attr) => {
				if attr.args =~ '^[a-zA-Z0-9]\+://'
					return
				endif

				lint.Attr(attr).Run()
			})

		Command.new("LLint")
			.Bar()
			.Bang()
			.Buffer()
			.Overlay()
			.NArgs(command.NArgs.Star)
			.Callback((attr) => {
				if attr.args =~ '^[a-zA-Z0-9]\+://'
					return
				endif

				lint.Attr(attr, true).Run()
			})
	}

	Autocmd.new('FileType')
		.Group(group)
		.Pattern([ft])
		.Replace()
		.Callback(Register)
endfor
