vim9script

import autoload "cgrep.vim"

cgrep.AddPruneDir(".git/", "__pycache__/", "dist-newstyle/", "node_modules/")
