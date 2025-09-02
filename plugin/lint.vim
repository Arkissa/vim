vim9script

import autoload 'linter.vim'

:command! -bang -nargs=* Lint linter.Run(!empty(<q-bang>), <q-args>)
