vim9script

import autoload 'grep.vim'

:command! -bang -nargs=* Grep grep.Grep.new(!empty(<q-bang>)).Run(<q-args>)

&grepprg = "cgrep -r"
&grepformat = "%-G,%f:%l:%c:%m"
