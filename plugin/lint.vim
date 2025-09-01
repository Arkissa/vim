vim9script

import autoload 'linter.vim'

:command! -bang Lint linter.Manager.RunLint(!empty(<q-bang>))

g:Linters = {
	go: [linter.Lint.new(["golangci-lint", "run"], ["%E%f:%l:%c:\\ Error%m", "%-G", "%-G%\\\\d%\\\\+\\ issues:", "%-G*\\ errcheck: %\\\\d%\\\\+"])]
}
