vim9script

import 'autocmd.vim'

type Autocmd = autocmd.Autocmd

class FuzzyFind
	var filescache: list<string> = []

	def new(group: string)
		Autocmd.new('CmdlineEnter')
			.Group(group)
			.Pattern([':'])
			.Callback(() => {
				this.filescache = []
			})
	enddef

	def Func(arg: any, cmdcomplete: any): list<string>
		this.filescache = this.filescache ?? globpath('.', '**', empty(&wildignore), true)
			->filter((_, fname) => !isdirectory(fname))
			->map((_, fname) => fnamemodify(fname, ':.'))

		return !arg->empty()
			? matchfuzzy(this.filescache, arg)
			: this.filescache
	enddef
endclass

const Find = FuzzyFind.new(g:myvimrc_group)
&findfunc = (a, c) => Find.Func(a, c)
