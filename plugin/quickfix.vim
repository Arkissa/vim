vim9script

import 'quickfix.vim'

&quickfixtextfunc = (d) => quickfix.Text.Func(d)
