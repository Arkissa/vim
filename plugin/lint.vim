vim9script

import autoload 'linter.vim'

:command! -bang -nargs=* Lint linter.Lint.new(!empty(<q-bang>)).Run(<q-args>)
