vim9script

import autoload 'linter.vim'

:command! -bang -nargs=* Lint linter.cmd.SetAttr({ bang: !empty(<q-bang>), args: <q-args> }).Run()
