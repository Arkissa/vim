vim9script

import autoload 'quickfix.vim'

&quickfixtextfunc = (d) => quickfix.Text.Func(d)
