vim9script

import 'parser.vim'
import 'command.vim'
import 'autocmd.vim'

type Command = command.Command
type Autocmd = autocmd.Autocmd

const group = 'Gitmodules'

Command.new('GitmodulesAst')
	.Callback(() => {
		if &filetype != 'gitconfig'
			return
		endif

		echo parser.ParseBuffer(bufnr())->string()
	})

Autocmd.new('BufEnter')
	.Group('group')
	.Pattern(['.gitmodule'])
	.Callback(() => {
		# if !exists('b:gitmodule_info') || b:gitmodule_info.changedtick != b:changedtick
		# 	b:gitmodule_info = {
		# 		ast: parser.ParseBuffer(bufnr()),
		# 		changedtick: b:changedtick,
		# 	}

		# 	return
		# endif

	})
