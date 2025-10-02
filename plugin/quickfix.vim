vim9script

import '../autoload/quickfixtext.vim'

&quickfixtextfunc = (d) => quickfixtext.Func(d)
