vim9script

import autoload 'quickfixtext/quickfixtext.vim'

&quickfixtextfunc = (d) => quickfixtext.Func(d)
