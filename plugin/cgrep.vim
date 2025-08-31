vim9script

import autoload "cgrep.vim"

cgrep.Config({
	dirs: [".git/", "__pycache__/", "dist-newstyle/", "node_modules/"]
})
