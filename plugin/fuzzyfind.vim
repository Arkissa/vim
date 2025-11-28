vim9script

import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

var filescache: list<string>

Autocmd.new('CmdlineEnter')
	.Group(g:myvimrc_group)
	.Pattern([':'])
	.Callback(() => {
		filescache = []
	})

def Find(arg: any, cmdcomplete: any): list<string>
	if filescache->empty()
		filescache = globpath('.', '**', true, true)
			->filter((_, fname) => !isdirectory(fname))
			->map((_, fname) => fnamemodify(fname, ':.'))
	endif

	return !arg->empty()
		? matchfuzzy(filescache, arg)
		: filescache
enddef

&findfunc = (a, c) => Find(a, c)
