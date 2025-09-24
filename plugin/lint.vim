vim9script

if !exists("g:LinterConfig")
	finish
endif

import '../autoload/command.vim'
import '../autoload/autocmd.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = "Linter"

def Lint(lint: command.Execute, onSaveCmd: string)
	if onSaveCmd != null_string
		Autocmd.new('BufWritePost')
			.Group(group)
			.Bufnr(bufnr())
			.Replace()
			.Command(onSaveCmd)
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
enddef

for [ft, conf] in g:LinterConfig->items()
	import autoload $'{conf.module}.vim'

	Autocmd.new('FileType')
		.Group(group)
		.Pattern([ft])
		.Replace()
		.Callback(funcref(Lint, [eval($'{fnamemodify(conf.module, ':t:r')}.Lint.new()'), conf->has_key('onSaveCmd') ? conf.onSaveCmd : null_string]))
endfor
