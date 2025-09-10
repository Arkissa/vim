vim9script

if !exists("g:Linters")
	finish
endif

import autoload 'command.vim'
import autoload 'autocmd.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

# type check
g:Linters->values()
	->map((_, d) => d.lint)
	->foreach((_, k: command.Execute) => {
	})

const group = "Linter"

const fts = g:Linters->keys()

Autocmd.new('FileType')
	.Group(group)
	.Pattern(fts)
	.Replace()
	.Callback(() => {
		var conf = g:Linters[&filetype]
		if conf->has_key('onSaveCmd')
			Autocmd.new('BufWritePost')
				.Group(group)
				.Bufnr(bufnr())
				.Replace()
				.Command(conf.onSaveCmd)
		endif

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

				conf.lint.Attr(attr).Run()
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

				conf.lint.Attr(attr, true).Run()
			})
	})
