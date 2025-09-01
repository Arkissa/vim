vim9script

import autoload 'linter.vim'

:command! -bang Lint linter.Job.Run(!empty(<q-bang>))
