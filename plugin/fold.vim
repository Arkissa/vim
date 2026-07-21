vim9script

def g:IndentFoldText(): string
	return repeat(' ', indent(v:foldstart)) .. foldtext()
enddef

&foldtext = 'g:IndentFoldText()'
