vim9script

import autoload 'path.vim'

var stateDir = path.OsStateDir()
&backupdir = stateDir .. '//'
&undodir   = stateDir .. '//'
