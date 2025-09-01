vim9script

import autoload 'linter.vim'

:command! -bang Lint linter.Manager.RunLint(empty(<q-bang>))

g:Linters = {
	go: [linter.Lint.new(["golangci-lint", "run"], ["%f:%l:%c:%m"])]
}
