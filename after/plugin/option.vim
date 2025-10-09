vim9script

import 'path.vim'

var stateDir = path.OsStateDir()
&backupdir = stateDir .. '//'
&undodir   = stateDir .. '//'
