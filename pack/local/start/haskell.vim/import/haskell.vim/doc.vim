vim9script

import 'haskell.vim/request.vim'

export class DocRequest extends request.Complete
	var _expr: string

	def new(this._expr)
	enddef

	def Cmd(): string
		return $':doc {this._expr}'
	enddef

	def Body(timeout: number = -1): list<string>
        var lines = super.Body(timeout)->split("\n")
        var i = lines->indexof((_, line) => line =~# '\v^\s*(--|\{-)')
        if i < 0
                return []
        endif

        return lines[start :]->mapnew((_, line) =>
                substitute(line, '\v^\s*(--|\{-)\s?[|^]?\s?|\s*-\}\s*$', '', 'g'))
	enddef
endclass
